import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui.shared
import qs.ui.screens.lock
import qs.ui.screens.greeter

PanelWindow {
    id: root

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    color: "black"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    focusable: true

    property real mouseX: 0
    property real mouseY: 0

    onVisibleChanged: {
        if (visible) {
            mainContentRect.forceActiveFocus()
        }
    }

    GreeterLogic {
        id: logic
    }

    Rectangle {
        id: mainContentRect
        anchors.fill: parent
        color: "black"
        focus: true

        onActiveFocusChanged: {
            if (!activeFocus && !logic.showSessionPicker) {
                mainContentRect.forceActiveFocus()
            }
        }
        Component.onCompleted: mainContentRect.forceActiveFocus()

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: (mouse) => {
                root.mouseX = (mouse.x - width / 2) / (width / 2)
                root.mouseY = (mouse.y - height / 2) / (height / 2)
            }
            onClicked: {
                logic.showSessionPicker = false
            }
        }

        Keys.onPressed: (event) => {
            logic.handleKey(event)
        }

        LockScreenBackground {
            id: background
            relativeMouseX: root.mouseX
            relativeMouseY: root.mouseY
        }

        LockScreenStatusBar {
            opacity: contentContainer.opacity
        }

        Item {
            id: contentContainer
            anchors.centerIn: parent
            width: authView.implicitWidth
            height: authView.implicitHeight

            transform: Translate {
                x: root.mouseX * (ThemeManager.lockParallaxIntensity / 2)
                y: root.mouseY * (ThemeManager.lockParallaxIntensity / 2)
                Behavior on x { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
            }

            GreeterAuthenticationView {
                id: authView
                logic: logic
                mouseX: root.mouseX
                mouseY: root.mouseY
            }
        }

        GreeterSessionPicker {
            logic: logic
        }

        GreeterPowerActions { }
    }
}
