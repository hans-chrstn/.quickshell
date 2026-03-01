import QtQuick
import Quickshell
import qs.core
import qs.ui.shared
import qs.ui.shared.shapes

CornerContainer {
    isAtTop: true
    isAtLeft: true
    aboveWindows: true
    
    firstFilletRotation: 0
    firstFilletX: expandedWidth - 1
    firstFilletY: 16
    
    secondFilletRotation: 270
    secondFilletX: 16
    secondFilletY: expandedHeight - 1
    
    customTopLeftRadius: 0
    customTopRightRadius: 0
    customBottomLeftRadius: 0
    customBottomRightRadius: ThemeManager.dynamicIslandCornerRadius
}
