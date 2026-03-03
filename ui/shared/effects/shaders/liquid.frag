#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float intensity;
    vec4 baseColor;
};

void main() {
    vec2 uv = qt_TexCoord0;
    
    float w1 = sin(uv.x * 3.5 + time * 0.8) * 0.12;
    float w2 = sin(uv.x * 2.0 + time * 0.5) * 0.15;
    float surface1 = 0.5 - ((w1 + w2) * intensity * 0.4);
    float body1 = smoothstep(surface1 - 0.05, surface1 + 0.05, uv.y);
    
    float w3 = sin(uv.x * 5.0 + time * 1.5) * 0.1;
    float w4 = sin(uv.x * 8.0 - time * 1.2) * 0.05;
    float surface2 = 0.6 - ((w3 + w4) * intensity * 0.5);
    float body2 = smoothstep(surface2 - 0.03, surface2 + 0.03, uv.y);
    
    float depth = smoothstep(1.0, 0.0, uv.y);
    
    float edge1 = smoothstep(0.04, 0.0, abs(uv.y - surface1)) * (0.3 + intensity);
    float edge2 = smoothstep(0.02, 0.0, abs(uv.y - surface2)) * (0.5 + intensity);
    
    float xFade = 1.0 - pow(abs(uv.x - 0.5) * 2.0, 6.0);
    
    vec4 col1 = baseColor * (body1 * 0.2 * depth + edge1 * 0.4);
    
    vec4 col2 = baseColor * (body2 * 0.3 * depth + edge2 * 0.6);
    
    float shimmer = sin(uv.x * 15.0 + uv.y * 10.0 + time * 2.5) * 0.05 * body2;
    
    vec4 finalColor = (col1 + col2 + (baseColor * shimmer)) * xFade;
    
    fragColor = finalColor * qt_Opacity;
}
