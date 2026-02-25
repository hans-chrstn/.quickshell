pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui.shared
import qs.ui.screens.lock

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    
    color: "transparent"

    Connections {
        target: root.lock
        function onUnlock() {
            SoundManager.playSuccess()
            unlockAnim.start()
        }
    }

    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            NumberAnimation { target: background; property: "opacity"; to: 0; duration: 500 }
            NumberAnimation { target: content; property: "scale"; to: 0.8; duration: 500; easing.type: Easing.InBack }
            NumberAnimation { target: content; property: "opacity"; to: 0; duration: 500 }
        }
        
        PropertyAction { target: root.lock; property: "locked"; value: false }
    }

    ParallelAnimation {
        id: initAnim
        running: true
        
        NumberAnimation { target: background; property: "opacity"; to: 1; duration: 500 }
        NumberAnimation { target: content; property: "scale"; to: 1; duration: 500; easing.type: Easing.OutBack }
        NumberAnimation { target: content; property: "opacity"; to: 1; duration: 500 }
    }

    Rectangle {
        id: mainRect
        anchors.fill: parent
        color: "black"
        
        focus: true
        onActiveFocusChanged: if (!activeFocus) mainRect.forceActiveFocus()
        Component.onCompleted: mainRect.forceActiveFocus()

        property real mouseX: 0
        property real mouseY: 0
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: (mouse) => {
                mainRect.mouseX = (mouse.x - width / 2) / (width / 2)
                mainRect.mouseY = (mouse.y - height / 2) / (height / 2)
            }
            onPressed: (mouse) => {
                mouse.accepted = false
            }
        }

        Keys.onPressed: (event) => {
            if (event.modifiers === (Qt.ShiftModifier | Qt.AltModifier) && event.key === Qt.Key_U) {
                root.lock.unlock()
                return
            }
            
            if (event.text.length === 1 || event.key === Qt.Key_Backspace) {
                SoundManager.playClick()
            }
            
            LockManager.processKeyEvent(event)
        }

        LockScreenBackground {
            id: background
            opacity: 0
            relativeMouseX: mainRect.mouseX
            relativeMouseY: mainRect.mouseY
        }

        LockScreenStatusBar {
            opacity: content.opacity
        }

        Item {
            id: content
            anchors.centerIn: parent
            width: innerLayout.implicitWidth
            height: innerLayout.implicitHeight
            scale: 0.8
            opacity: 0
            
            transform: Translate {
                x: mainRect.mouseX * (ThemeManager.lockParallaxIntensity / 2)
                y: mainRect.mouseY * (ThemeManager.lockParallaxIntensity / 2)
                Behavior on x { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
            }

            ColumnLayout {
                id: innerLayout
                anchors.centerIn: parent
                spacing: ThemeManager.lockContentSpacing
                
                LockScreenClock { }

                LockScreenAuthenticationView { }
                
                Text {
                    id: statusMsg
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 350
                    horizontalAlignment: Text.AlignHCenter
                    text: LockManager.statusMessage
                    color: LockManager.isErrorMessage ? ThemeManager.dangerColor : "white"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    wrapMode: Text.Wrap
                    opacity: text ? 0.8 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                LockScreenMediaControls { }
            }
        }

        ColumnLayout {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 20
            spacing: 15
            opacity: content.opacity

            LockScreenNotificationIndicator { 
                Layout.alignment: Qt.AlignHCenter
            }

            Text { 
                id: emergencyHint
                Layout.alignment: Qt.AlignHCenter
                text: "SHIFT + ALT + U TO BYPASS"
                color: "white"
                opacity: 0.15
                font.pixelSize: 9
                font.letterSpacing: 3
                font.weight: Font.Black
            }
        }
    }
}
