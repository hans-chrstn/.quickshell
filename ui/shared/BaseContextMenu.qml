import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import qs.core
import qs.ui.shared

Menu {
    id: root

    property bool isOpen: false
    property bool keepDashboardOpen: false

    property alias menuX: root.x
    property alias menuY: root.y

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    onOpened: {
        if (root.keepDashboardOpen) {
            ViewManager.activeContextMenus++
        }
    }

    onClosed: {
        if (root.keepDashboardOpen) {
            ViewManager.activeContextMenus--
        }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: ThemeManager.durationFast
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.95
                to: 1
                duration: ThemeManager.durationFast
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: ThemeManager.durationFast
            }
            NumberAnimation {
                property: "scale"
                from: 1
                to: 0.98
                duration: ThemeManager.durationFast
            }
        }
    }

    background: Rectangle {
        radius: ThemeManager.radiusLarge
        color: ThemeManager.backgroundPrimaryColor
        border.color: ThemeManager.outlineStrongColor
        border.width: 1
        opacity: 0.98

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowOpacity: 0.6
            shadowBlur: 25
            shadowVerticalOffset: 8
        }
    }

    padding: 6

    Connections {
        target: ViewManager

        function onLeftDashboardOpenChanged() {
            if (!ViewManager.leftDashboardOpen) {
                root.close()
            }
        }
    }
}
