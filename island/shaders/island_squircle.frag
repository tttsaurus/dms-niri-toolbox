#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 sizePx;
} ubuf;

float sdfSquircle(vec2 p, vec2 halfSize) {
    vec2 h = max(halfSize, vec2(1.0));
    vec2 q = abs(p) / h;

    const float n = 4.0;
    float implicitShape = pow(pow(q.x, n) + pow(q.y, n), 1.0 / n) - 1.0;

    return implicitShape * min(h.x, h.y);
}

void main() {
    vec2 size = max(ubuf.sizePx, vec2(1.0));
    vec2 p = (qt_TexCoord0 - vec2(0.5)) * size;

    float distanceToEdge = sdfSquircle(p, size * 0.5);
    float aa = max(fwidth(distanceToEdge), 0.75);
    float coverage = 1.0 - smoothstep(-aa, aa, distanceToEdge);

    fragColor = vec4(0.0, 0.0, 0.0, coverage * ubuf.qt_Opacity);
}
