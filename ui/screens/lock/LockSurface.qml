pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui.shared
import qs.ui.screens.lock

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    
    color: "black"

    Connections {
        target: root.lock
        function onRequestDismiss() {
            mainRect.enforceFocus = false
            dismissAnim.start()
        }
    }

    SequentialAnimation {
        id: dismissAnim
        
        ParallelAnimation {
            NumberAnimation { 
                target: backgroundContainer
                property: "opacity"
                to: 0
                duration: 300 
            }
            NumberAnimation { 
                target: content
                property: "scale"
                to: 0.9
                duration: 300
                easing.type: Easing.InCubic 
            }
            NumberAnimation { 
                target: content
                property: "opacity"
                to: 0
                duration: 300 
            }
        }
        
        ScriptAction {
            script: dismissTimer.start()
        }
    }

    Timer {
        id: dismissTimer
        interval: 50
        onTriggered: {
            if (root.lock) root.lock.locked = false
        }
    }

    ParallelAnimation {
        id: initAnim
        running: true
        
        NumberAnimation { 
            target: backgroundContainer
            property: "opacity"
            from: 0
            to: 1
            duration: 500 
        }
        NumberAnimation { 
            target: content
            property: "scale"
            from: 0.8
            to: 1
            duration: 500
            easing.type: Easing.OutBack 
        }
        NumberAnimation { 
            target: content
            property: "opacity"
            from: 0
            to: 1
            duration: 500 
        }
    }

    Rectangle {
        id: mainRect
        anchors.fill: parent
        color: "black"
        
        property bool enforceFocus: true

        focus: true
        onActiveFocusChanged: {
            if (!activeFocus && enforceFocus && root.lock && root.lock.locked) {
                mainRect.forceActiveFocus()
            }
        }
        Component.onCompleted: {
            mainRect.forceActiveFocus()
        }

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
            if (event.text.length === 1 || event.key === Qt.Key_Backspace) {
                SoundManager.playClick()
            }
            LockManager.processKeyEvent(event)
        }

        LazyContainer {
            id: backgroundContainer
            anchors.fill: parent
            opacity: 0
            
            component: LockScreenBackground {
                relativeMouseX: mainRect.mouseX
                relativeMouseY: mainRect.mouseY
            }
        }

        LazyContainer {
            id: statusBarContainer
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 60
            anchors.leftMargin: 60
            anchors.rightMargin: 60
            height: 60
            opacity: content.opacity
            
            component: LockScreenStatusBar { }
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

                StyledLabel {
                    id: statusMsg
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 350
                    horizontalAlignment: Text.AlignHCenter
                    text: LockManager.statusMessage
                    type: "lockStatus"
                    customColor: LockManager.isErrorMessage ? ThemeManager.dangerColor : "white"
                    wrapMode: Text.Wrap
                    opacity: text ? 0.8 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                LazyContainer {
                    id: mediaControlsWrapper
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 400
                    Layout.preferredHeight: 150
                    
                    component: LockScreenMediaControls { }
                }
            }
        }

        ColumnLayout {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 20
            spacing: 15
            opacity: content.opacity

            LazyContainer {
                id: notifIndicatorWrapper
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 300
                Layout.preferredHeight: 32
                
                component: LockScreenNotificationIndicator { }
            }
        }
    }
}
