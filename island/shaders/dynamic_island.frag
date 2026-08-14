#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    vec2 sizeDip;
    float radiusDip;

    vec4 baseColor;
    vec4 glowColor;
    vec4 edgeColor;

    float time;
    float edgeStrength;
    float flowStrength;

    float shapeInset;

    float interiorGlow;
    float innerEdgeHighlight;
} ubuf;

float sdfSquircle(vec2 p, vec2 halfSize, float radius) {
    radius = clamp(radius, 0.0, min(halfSize.x, halfSize.y));

    vec2 q = abs(p) - halfSize + vec2(radius);
    vec2 outside = max(q, vec2(0.0));

    const float n = 4.0;

    float squircleDistance = pow(pow(outside.x, n) + pow(outside.y, n), 1.0 / n);
    float insideDistance = min(max(q.x, q.y), 0.0);

    return squircleDistance + insideDistance - radius;
}

vec2 sdfNormal(vec2 p, vec2 halfSize, float radius) {
    const float epsilon = 0.75;

    float dx = sdfSquircle(p + vec2(epsilon, 0.0), halfSize, radius) - sdfSquircle(p - vec2(epsilon, 0.0), halfSize, radius);
    float dy = sdfSquircle(p + vec2(0.0, epsilon), halfSize, radius) - sdfSquircle(p - vec2(0.0, epsilon), halfSize, radius);

    vec2 gradient = vec2(dx, dy);
    float lengthSquared = dot(gradient, gradient);

    if (lengthSquared < 0.000001) {
        return vec2(0.0, -1.0);
    }

    return gradient * inversesqrt(lengthSquared);
}

float gaussian(float value, float sharpness) {
    return exp(-value * value * sharpness);
}

void main() {
    vec2 size = max(ubuf.sizeDip, vec2(1.0));

    vec2 halfSize = max(size * 0.5 - vec2(ubuf.shapeInset), vec2(1.0));
    float radius = max(ubuf.radiusDip - ubuf.shapeInset, 0.0);

    vec2 p = (qt_TexCoord0 - vec2(0.5)) * size;

    float distanceToEdge = sdfSquircle(p, halfSize, radius);
    float aa = max(fwidth(distanceToEdge), 0.001);
    float coverage = smoothstep(aa, -aa, distanceToEdge);

    if (coverage <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    float insideDistance = max(-distanceToEdge, 0.0);
    float minSize = min(size.x, size.y);

    vec2 centered = qt_TexCoord0 - vec2(0.5);
    vec2 materialPos = centered;

    materialPos.x *= size.x / max(size.y, 1.0);

    float centerDistance = length(materialPos);
    float centerGlow = 1.0 - smoothstep(0.05, 0.85, centerDistance);

    vec3 color = ubuf.baseColor.rgb;

    float bodyGlowFactor = 0.88 + centerGlow * 0.12;
    color *= mix(1.0, bodyGlowFactor, ubuf.interiorGlow);

    vec2 glowCenterA = vec2(0.42 * cos(ubuf.time), 0.23 * sin(ubuf.time * 2.0));
    vec2 deltaA = materialPos - glowCenterA;
    float glowA = exp(-dot(deltaA, deltaA) * 4.5);

    vec2 glowCenterB = vec2(-0.34 * cos(ubuf.time * 2.0), 0.18 * sin(ubuf.time));
    vec2 deltaB = materialPos - glowCenterB;
    float glowB = exp(-dot(deltaB, deltaB) * 7.0);

    vec2 flowDirection = normalize(vec2(0.82, -0.57));
    float flowCoordinate = dot(materialPos, flowDirection);
    float flowPosition = 0.55 * sin(ubuf.time);
    float flowingBand = gaussian(flowCoordinate - flowPosition, 5.5);

    float interiorLight = glowA * 0.55 + glowB * 0.28 + flowingBand * 0.42;

    color += ubuf.glowColor.rgb * interiorLight * 0.20 * ubuf.flowStrength * ubuf.interiorGlow;

    float rimWidth = clamp(minSize * 0.025, 1.5, 4.0);
    float bevelWidth = clamp(minSize * 0.11, 4.0, 14.0);

    float rimMask = 1.0 - smoothstep(0.0, rimWidth, insideDistance);
    float bevelMask = 1.0 - smoothstep(0.0, bevelWidth, insideDistance);

    vec2 normal2D = sdfNormal(p, halfSize, radius);

    float lightAngle = -2.30 + sin(ubuf.time) * 0.18;
    vec2 keyDirection = vec2(cos(lightAngle), sin(lightAngle));

    vec3 lightDirection = normalize(vec3(keyDirection * 0.92, 1.30));
    vec3 viewDirection = vec3(0.0, 0.0, 1.0);

    vec3 surfaceNormal = normalize(vec3(normal2D * bevelMask * 1.45, 1.0));

    float diffuse = max(dot(surfaceNormal, lightDirection), 0.0);
    vec3 halfwayDirection = normalize(lightDirection + viewDirection);
    float specular = pow(max(dot(surfaceNormal, halfwayDirection), 0.0), 26.0);

    specular *= bevelMask;

    float bevelShade = mix(0.84, 1.10, diffuse);

    color *= mix(1.0, bevelShade, bevelMask * 0.65);

    float keyRim = pow(max(dot(normal2D, keyDirection), 0.0), 1.35);
    float oppositeRim = pow(max(dot(normal2D, -keyDirection), 0.0), 2.2);

    float rimLight = rimMask * (0.08 + keyRim * 1.25 + oppositeRim * 0.42);

    color += ubuf.edgeColor.rgb * rimLight * ubuf.edgeStrength;
    color += ubuf.edgeColor.rgb * specular * 0.65 * ubuf.edgeStrength * mix(rimMask, 1.0, ubuf.innerEdgeHighlight);

    float innerRim = bevelMask * (1.0 - rimMask) * diffuse;

    color += ubuf.glowColor.rgb * innerRim * 0.055 * ubuf.innerEdgeHighlight;

    float alpha = coverage * ubuf.qt_Opacity;

    fragColor = vec4(max(color, vec3(0.0)) * alpha, alpha);
}