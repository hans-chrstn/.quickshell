#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 color1;
    vec4 color2;
    vec4 color3;
    float time;
};

float blob(vec2 uv, vec2 center, float size, float speed) {
    vec2 p = uv - center;
    p += vec2(sin(time * speed), cos(time * speed)) * 0.1;
    return smoothstep(size, size - 0.1, length(p));
}

void main() {
    vec2 uv = qt_TexCoord0;
    
    float b1 = blob(uv, vec2(0.3, 0.3), 0.4, 0.5);
    float b2 = blob(uv, vec2(0.7, 0.7), 0.4, 0.7);
    float b3 = blob(uv, vec2(0.5, 0.5), 0.5, 0.3);
    
    vec4 finalColor = mix(color1, color2, b1);
    finalColor = mix(finalColor, color3, b2);
    finalColor = mix(finalColor, vec4(0.0), 1.0 - max(b1, max(b2, b3)));
    
    fragColor = finalColor * qt_Opacity;
}
