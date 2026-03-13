import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.ui.shared
import qs.ui.shared.effects

PopupWindow {
    id: root

    anchor {
        window: root.targetWindow
        rect.x: root.targetX
        rect.y: root.targetY
        gravity: root.isAtBottom ? 1 : 3
        margins {
            top: 10
            bottom: 10
            left: 10
            right: 10
        }
    }

    property var targetWindow: null
    property real targetX: 0
    property real targetY: 0
    property bool isAtBottom: false

    visible: TooltipManager.active && TooltipManager.targetItem !== null
    
    implicitWidth: Math.max(120, layout.implicitWidth + 32)
    implicitHeight: layout.implicitHeight + 20
    
    Item {
        id: tooltipContent
        anchors.fill: parent
        
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.9
        
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }

        AdvancedGlass {
            anchors.fill: parent
            cornerRadius: 12
            blurRadius: 32
            overlayOpacity: 0.8
            overlayColor: ThemeManager.backgroundColor
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowOpacity: 0.4
                shadowBlur: 0.5
                shadowVerticalOffset: 4
            }
        }

        ColumnLayout {
            id: layout
            anchors.centerIn: parent
            spacing: 2
            
            StyledLabel {
                text: TooltipManager.text ? TooltipManager.text.toUpperCase() : ""
                type: "trayTooltip"
                Layout.alignment: Qt.AlignHCenter
                customColor: ThemeManager.accentColor
                font.weight: Font.Black
            }
            
            StyledLabel {
                text: TooltipManager.description || ""
                type: "caption"
                visible: text !== ""
                opacity: 0.6
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 8
                font.weight: Font.Medium
            }
        }
    }

    function updatePosition() {
        if (TooltipManager.active && TooltipManager.targetItem) {
            let item = TooltipManager.targetItem
            let win = item.Window ? item.Window.window : null
            
            if (win) {
                root.targetWindow = win
                let pos = item.mapToItem(null, 0, 0)
                
                root.targetX = pos.x + (item.width / 2) - (root.implicitWidth / 2)
                
                root.targetY = pos.y
                
                root.isAtBottom = !!(win.anchors && win.anchors.bottom)
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            updatePosition()
        }
    }

    Connections {
        target: TooltipManager
        function onActiveChanged() {
            if (TooltipManager.active) {
                Qt.callLater(root.updatePosition)
            }
        }
    }
}
