import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.shared
import qs.ui.shared.shapes
import "./topright"
import qs.ui.features.island.corners.shared

CornerContainer {
    id: root
    isAtTop: true
    isAtRight: true
    aboveWindows: true
    isHoverEnabled: true
    
    readonly property int activeButtons: {
        let count = 0
        if (ThemeManager.showCornerWallpaper) {
            count++
        }
        if (ThemeManager.showCornerSnap) {
            count++
        }
        if (ThemeManager.showCornerRecord) {
            count++
        }
        if (ThemeManager.showCornerTasks) {
            count++
        }
        if (ThemeManager.showCornerNotes) {
            count++
        }
        return count
    }

    expandedWidth: Math.max(80, activeButtons * 70)
    expandedHeight: 100
    
    firstFilletRotation: 0
    firstFilletX: -ThemeManager.dynamicIslandCornerRadius
    firstFilletY: 16
    
    secondFilletRotation: 0
    secondFilletX: expandedWidth - ThemeManager.dynamicIslandCornerRadius - 16 
    secondFilletY: 100

    customTopLeftRadius: 0
    customTopRightRadius: 0
    customBottomLeftRadius: ThemeManager.dynamicIslandCornerRadius
    customBottomRightRadius: 0

    Row {
        anchors.centerIn: parent
        spacing: 20
        
        UtilityButton {
            visible: ThemeManager.showCornerWallpaper
            iconText: ThemeManager.iconImage
            labelText: "WALL"
            onClicked: {
                ViewManager.toggleWallpaper()
            }
        }

        UtilityButton {
            visible: ThemeManager.showCornerSnap
            iconText: ThemeManager.iconSnap
            labelText: "SNAP"
            onClicked: {
                Quickshell.execDetached(["niri", "msg", "action", "screenshot"])
            }
        }
        
        RecordButton {
            visible: ThemeManager.showCornerRecord
            screen: root.screen
        }

        UtilityButton {
            visible: ThemeManager.showCornerTasks
            iconText: ThemeManager.iconTasks
            labelText: "TASKS"
            onClicked: {
                ViewManager.toggleTaskManager()
            }
        }

        UtilityButton {
            visible: ThemeManager.showCornerNotes
            iconText: ThemeManager.iconFile
            labelText: "NOTES"
            onClicked: {
                ViewManager.toggleNotes()
            }
        }
    }
}
