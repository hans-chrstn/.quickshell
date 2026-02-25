import QtQuick
import Quickshell
import qs.core
import qs.ui.shared

CornerContainer {
    isAtBottom: true
    isAtLeft: true
    aboveWindows: true
    
    firstFilletRotation: 90
    firstFilletX: expandedWidth - 1
    firstFilletY: expandedHeight - surfaceCornerRadius - ThemeManager.dynamicIslandCornerRadius
    
    secondFilletRotation: 180
    secondFilletX: 16
    secondFilletY: -20 + 1
    
    customTopLeftRadius: 0
    customTopRightRadius: ThemeManager.dynamicIslandCornerRadius
    customBottomLeftRadius: 0
    customBottomRightRadius: 0
}
