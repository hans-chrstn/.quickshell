#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 mousePos;
    float intensity;
};

void main() {
    float d = distance(qt_TexCoord0, mousePos);
    
    float highlight = smoothstep(1.2, 0.0, d) * 0.25;
    
    float sheen = smoothstep(0.5, 0.0, d) * 0.35;
    
    float alpha = (highlight + sheen) * intensity;
    
    fragColor = vec4(vec3(alpha), alpha) * qt_Opacity;
}
