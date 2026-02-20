import QtQuick
import Quickshell
import qs.config
import qs.components

ScreenCorner {
    activeTop: true
    activeLeft: true
    aboveWindows: true
    
    f1Rot: 0
    f1X: expandedWidth - 1
    f1Y: 16
    
    f2Rot: 270
    f2X: 16
    f2Y: expandedHeight - 1
    
    customTL: 0
    customTR: 0
    customBL: 0
    customBR: FrameConfig.dynamicIslandCornerRadius
}
