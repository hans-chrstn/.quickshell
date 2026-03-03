#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float intensity;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 dist = uv - 0.5;
    
    vec4 c = texture(source, uv);
    float r = texture(source, uv + dist * intensity).r;
    float g = c.g;
    float b = texture(source, uv - dist * intensity).b;
    
    fragColor = vec4(r, g, b, c.a) * qt_Opacity;
}
