#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    vec2 sizeDip;
    float radiusDip;
} ubuf;

float sdfSquircle(vec2 p, vec2 halfSize, float radius) {
    radius = clamp(
        radius,
        0.0,
        min(halfSize.x, halfSize.y)
    );

    vec2 q = abs(p) - halfSize + vec2(radius);
    vec2 outside = max(q, vec2(0.0));

    const float n = 4.0;
    float squircleDistance = pow(pow(outside.x, n) + pow(outside.y, n), 1.0 / n);
    float insideDistance = min(max(q.x, q.y), 0.0);

    return squircleDistance + insideDistance - radius;
}

void main() {
    vec2 size = max(ubuf.sizeDip, vec2(1.0));
    vec2 halfSize = size * 0.5;
    vec2 p = (qt_TexCoord0 - vec2(0.5)) * size;

    float distanceToEdge = sdfSquircle(p, halfSize, ubuf.radiusDip);
    float aa = max(fwidth(distanceToEdge), 0.75);
    float coverage = 1.0 - smoothstep(-aa, aa, distanceToEdge);

    fragColor = vec4(0.0, 0.0, 0.0, coverage * ubuf.qt_Opacity);
}