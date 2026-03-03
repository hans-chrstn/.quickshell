#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uWidth;
    float uHeight;
    float radius;
    vec2 rippleCenter;
    float rippleSize;
    float rippleAlpha;
    vec4 baseColor;
};

float sdRoundRect(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 pos = qt_TexCoord0 * vec2(uWidth, uHeight);
    vec2 halfSize = vec2(uWidth, uHeight) * 0.5;
    
    float d = sdRoundRect(pos - halfSize, halfSize, radius);
    float edgeSoftness = max(fwidth(d), 0.5);
    float mask = 1.0 - smoothstep(-edgeSoftness, edgeSoftness, d);
    
    if (mask <= 0.0 || rippleAlpha <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    
    float distToCenter = length(pos - rippleCenter);
    
    float waveWidth = min(uWidth, uHeight) * 0.4;
    float wave = smoothstep(rippleSize - waveWidth, rippleSize, distToCenter) * 
                 (1.0 - smoothstep(rippleSize, rippleSize + 2.0, distToCenter));
    
    vec4 col = baseColor * wave * rippleAlpha * 3.0;
    
    float rippleFill = 1.0 - smoothstep(rippleSize - 1.0, rippleSize + 1.0, distToCenter);
    col += baseColor * rippleFill * rippleAlpha * 0.4;
    
    fragColor = col * mask * qt_Opacity;
}
