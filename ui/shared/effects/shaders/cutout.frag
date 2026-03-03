#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 rect; 
};

void main() {
    vec2 uv = qt_TexCoord0;
    
    float xMin = rect.x;
    float xMax = rect.x + rect.z;
    float yMin = rect.y;
    float yMax = rect.y + rect.w;

    bool insideX = uv.x >= xMin && uv.x <= xMax;
    bool insideY = uv.y >= yMin && uv.y <= yMax;
    bool inside = insideX && insideY;
    
    float dimAlpha = 0.6;
    
    float borderThickness = 0.0015;
    
    float distToLeft = abs(uv.x - xMin);
    float distToRight = abs(uv.x - xMax);
    float distToTop = abs(uv.y - yMin);
    float distToBottom = abs(uv.y - yMax);
    
    bool onVerticalEdge = (distToLeft < borderThickness || distToRight < borderThickness) && insideY;
    bool onHorizontalEdge = (distToTop < borderThickness || distToBottom < borderThickness) && insideX;
    bool onBorder = onVerticalEdge || onHorizontalEdge;
    
    vec4 col = vec4(0.0);
    
    if (onBorder) {
        col = vec4(1.0, 1.0, 1.0, 0.9);
    } else if (!inside) {
        col = vec4(0.0, 0.0, 0.0, dimAlpha);
    }
    
    fragColor = col * qt_Opacity;
}
