import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui.shared
import qs.ui.shared.effects

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    readonly property string screenName: (root.screen) ? root.screen.name : ""
    visible: AreaPickerManager.active && (AreaPickerManager.activeScreenName === screenName)

    onVisibleChanged: {
        if (visible) {
            interactionArea.forceActiveFocus()
        }
    }

    AreaCutout {
        id: visualEffect
        anchors.fill: parent
    }

    MouseArea {
        id: interactionArea
        anchors.fill: parent
        hoverEnabled: true
        
        onPressed: (mouse) => {
            AreaPickerManager.startPoint = Qt.point(mouse.x, mouse.y)
        }

        onPositionChanged: (mouse) => {
            if (pressed) {
                AreaPickerManager.update(Qt.point(mouse.x, mouse.y))
            }
        }

        onReleased: {
            AreaPickerManager.finish()
        }
    }

    Rectangle {
        id: helperLabel
        anchors.centerIn: parent
        width: helperText.implicitWidth + 40
        height: 40
        radius: 20
        color: ThemeManager.backgroundPrimaryColor
        border.color: ThemeManager.accentColor
        border.width: 1
        opacity: AreaPickerManager.selection.width < 10 ? 0.9 : 0
        visible: opacity > 0.01
        
        Behavior on opacity { NumberAnimation { duration: 300 } }

        StyledLabel {
            id: helperText
            anchors.centerIn: parent
            text: "Drag to select | Space for Whole Screen | ESC to Cancel"
            type: "caption"
            font.weight: Font.Black
            letterSpacing: 1
        }
    }

    Rectangle {
        id: resolutionPill
        width: resLabel.implicitWidth + 20
        height: 24
        radius: 12
        color: ThemeManager.backgroundPrimaryColor
        border.color: ThemeManager.accentColor
        border.width: 1
        opacity: AreaPickerManager.selection.width > 10 ? 0.9 : 0
        
        x: {
            let targetX = AreaPickerManager.selection.x + AreaPickerManager.selection.width - width
            return Math.max(10, Math.min(parent.width - width - 10, targetX))
        }
        y: {
            let targetY = AreaPickerManager.selection.y + AreaPickerManager.selection.height + 10
            return Math.max(10, Math.min(parent.height - height - 10, targetY))
        }

        StyledLabel {
            id: resLabel
            anchors.centerIn: parent
            text: Math.round(AreaPickerManager.selection.width) + " x " + Math.round(AreaPickerManager.selection.height)
            type: "caption"
            font.weight: Font.Black
        }
        
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: {
            AreaPickerManager.cancel()
        }
    }

    Shortcut {
        sequence: "Space"
        enabled: root.visible
        onActivated: {
            AreaPickerManager.selectWholeScreen(root.width, root.height)
        }
    }
}
