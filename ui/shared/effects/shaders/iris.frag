#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float uWidth;
    float uHeight;
    float radius;
    float aspectRatio;
};

layout(binding = 1) uniform sampler2D source;

float sdRoundRect(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 pos = qt_TexCoord0 * vec2(uWidth, uHeight);
    vec2 halfSize = vec2(uWidth, uHeight) * 0.5;
    
    float d = sdRoundRect(pos - halfSize, halfSize, radius);
    float edgeSoftness = max(fwidth(d), 0.5);
    float pillMask = 1.0 - smoothstep(-edgeSoftness, edgeSoftness, d);
    
    if (pillMask <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 uv = qt_TexCoord0;
    vec2 distVec = uv - vec2(0.5);
    distVec.x *= aspectRatio;
    float bloomDist = length(distVec);
    
    float maxDist = length(vec2(0.5 * aspectRatio, 0.5));
    float bloomRadius = progress * maxDist * 1.1; 
    
    float bloomEdge = 0.25;
    float mask = 1.0 - smoothstep(bloomRadius - bloomEdge, bloomRadius, bloomDist);
    
    float edgeWidth = 0.08;
    float shimmer = smoothstep(bloomRadius - edgeWidth, bloomRadius, bloomDist) * 
                    (1.0 - smoothstep(bloomRadius, bloomRadius + 0.02, bloomDist));
    
    vec4 color = texture(source, uv);
    
    vec4 finalColor = color * mask;
    finalColor.rgb += (vec3(1.0) * shimmer * 0.3 * progress);
    
    fragColor = finalColor * pillMask * progress * qt_Opacity;
}
