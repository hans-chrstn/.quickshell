import QtQuick
import Quickshell
import qs.services
import qs.components

ScreenCorner {
    activeBottom: true
    activeLeft: true
    aboveWindows: true
    
    f1Rot: 90
    f1X: expandedWidth - 1
    f1Y: expandedHeight - sRadius - ThemeManager.dynamicIslandCornerRadius
    
    f2Rot: 180
    f2X: 16
    f2Y: -20 + 1
    
    customTL: 0
    customTR: ThemeManager.dynamicIslandCornerRadius
    customBL: 0
    customBR: 0
}
