#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float offset;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 d = vec2(offset) / vec2(textureSize(source, 0));
    
    vec4 c = texture(source, uv);
    c += texture(source, uv + vec2(d.x, d.y));
    c += texture(source, uv + vec2(d.x, -d.y));
    c += texture(source, uv + vec2(-d.x, d.y));
    c += texture(source, uv + vec2(-d.x, -d.y));
    
    fragColor = (c / 5.0) * qt_Opacity;
}
