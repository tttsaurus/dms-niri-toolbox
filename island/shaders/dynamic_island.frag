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
    float shadowWidth;
    float shadowIntensity;

    float interiorGlow;
    float innerEdgeHighlight;

    float enableSplit;
    float splitPercentage;
} ubuf;

struct ShapeSample {
    vec2 p;
    vec2 halfSize;
    float radius;
    float distance;
};

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

ShapeSample sampleShape(vec2 p, vec2 halfSize, float radius) {
    ShapeSample sample_;

    sample_.p = p;
    sample_.halfSize = halfSize;
    sample_.radius = radius;
    sample_.distance = sdfSquircle(p, halfSize, radius);

    return sample_;
}

ShapeSample sampleGeometry(vec2 p, vec2 halfSize, float radius) {
    ShapeSample wholeShape = sampleShape(p, halfSize, radius);

    float splitProgress = clamp(ubuf.enableSplit, 0.0, 1.0);

    if (splitProgress <= 0.0) {
        return wholeShape;
    }

    float percentage = clamp(ubuf.splitPercentage, 0.01, 0.99);

    float fullWidth = halfSize.x * 2.0;
    float splitGap = max(ubuf.shapeInset * 2.0, 2.0);

    float minPieceWidth = radius * 2.0 + 0.001;
    float availableWidth = fullWidth - splitGap;

    if (availableWidth <= minPieceWidth * 2.0) {
        return wholeShape;
    }

    float targetLeftWidth = availableWidth * percentage;

    targetLeftWidth = clamp(targetLeftWidth, minPieceWidth, availableWidth - minPieceWidth);

    float targetRightWidth = availableWidth - targetLeftWidth;

    float targetLeftCenter = -halfSize.x + targetLeftWidth * 0.5;
    float targetRightCenter = halfSize.x - targetRightWidth * 0.5;

    float leftWidth = mix(fullWidth, targetLeftWidth, splitProgress);
    float rightWidth = mix(fullWidth, targetRightWidth, splitProgress);

    float leftCenter = mix(0.0, targetLeftCenter, splitProgress);
    float rightCenter = mix(0.0, targetRightCenter, splitProgress);

    vec2 leftHalfSize = vec2(leftWidth * 0.5, halfSize.y);
    vec2 rightHalfSize = vec2(rightWidth * 0.5, halfSize.y);

    ShapeSample leftShape = sampleShape(p - vec2(leftCenter, 0.0), leftHalfSize, radius);
    ShapeSample rightShape = sampleShape(p - vec2(rightCenter, 0.0), rightHalfSize, radius);

    if (leftShape.distance <= rightShape.distance) {
        return leftShape;
    }

    return rightShape;
}

void main() {
    vec2 size = max(ubuf.sizeDip, vec2(1.0));

    vec2 baseHalfSize = max(size * 0.5 - vec2(ubuf.shapeInset), vec2(1.0));
    float baseRadius = max(ubuf.radiusDip - ubuf.shapeInset, 0.0);

    baseRadius = clamp(baseRadius, 0.0, min(baseHalfSize.x, baseHalfSize.y));

    vec2 globalP = (qt_TexCoord0 - vec2(0.5)) * size;

    ShapeSample shape = sampleGeometry(globalP, baseHalfSize, baseRadius);

    vec2 p = shape.p;
    vec2 halfSize = shape.halfSize;
    float radius = shape.radius;
    float distanceToEdge = shape.distance;

    float aa = max(fwidth(distanceToEdge), 0.001);
    float coverage = smoothstep(aa, -aa, distanceToEdge);

    float insideDistance = max(-distanceToEdge, 0.0);

    vec2 localSize = halfSize * 2.0;
    float minSize = min(localSize.x, localSize.y);

    float aspectRatio = localSize.x / max(localSize.y, 1.0);
    float widthMix = 0.65 * smoothstep(1.3, 4.5, aspectRatio);
    float materialWidth = mix(localSize.y, localSize.x, widthMix);
    vec2 materialPos = vec2(p.x / max(materialWidth, 1.0), p.y / max(localSize.y, 1.0));

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

    float maxShadowWidth = max(ubuf.shapeInset - 0.001, 0.0);
    float shadowWidth = clamp(ubuf.shadowWidth, 0.0, maxShadowWidth);

    float shadowAlpha = 0.0;

    if (shadowWidth > 0.0) {
        float outsideDistance = max(distanceToEdge, 0.0);

        float shadowBand = 1.0 - smoothstep(0.0, shadowWidth, outsideDistance);
        float outsideMask = 1.0 - coverage;
        float shadowSideMask = smoothstep(-0.55, 0.0, normal2D.y);

        shadowAlpha = shadowBand * outsideMask * shadowSideMask * clamp(ubuf.shadowIntensity, 0.0, 0.9) * ubuf.qt_Opacity;
    }

    vec4 body = vec4(max(color, vec3(0.0)) * alpha, alpha);
    vec4 shadow = vec4(0.0, 0.0, 0.0, shadowAlpha);

    fragColor = body + shadow * (1.0 - body.a);
}