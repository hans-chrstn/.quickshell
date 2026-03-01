import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.shared
import qs.ui.shared.shapes
import "./topright"

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
    firstFilletX: -20 - 10
    firstFilletY: 16
    
    secondFilletRotation: 0
    secondFilletX: expandedWidth - 20 - 16 - 10
    secondFilletY: 100 - 1

    customTopLeftRadius: 0
    customTopRightRadius: 0
    customBottomLeftRadius: ThemeManager.dynamicIslandCornerRadius
    customBottomRightRadius: 0

    Row {
        anchors.centerIn: parent
        spacing: 20
        
        UtilityButton {
            visible: ThemeManager.showCornerWallpaper
            iconText: "󰸉"
            labelText: "WALL"
            onClicked: {
                ViewManager.toggleWallpaper()
            }
        }

        UtilityButton {
            visible: ThemeManager.showCornerSnap
            iconText: "󰄀"
            labelText: "SNAP"
            onClicked: {
                Quickshell.execDetached(["niri", "msg", "action", "screenshot"])
            }
        }
        
        RecordButton {
            visible: ThemeManager.showCornerRecord
            screenIdentifier: root.screenIdentifier
        }

        UtilityButton {
            visible: ThemeManager.showCornerTasks
            iconText: "󰍛"
            labelText: "TASKS"
            onClicked: {
                ViewManager.toggleTaskManager()
            }
        }

        UtilityButton {
            visible: ThemeManager.showCornerNotes
            iconText: "󰠮"
            labelText: "NOTES"
            onClicked: {
                ViewManager.toggleNotes()
            }
        }
    }
}
