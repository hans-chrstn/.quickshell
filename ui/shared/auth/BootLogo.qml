import QtQuick
import QtQuick.Effects
import qs.core

Item {
    id: root

    anchors.fill: parent
    
    signal finished()

    readonly property color accent: ThemeManager.accentColor

    property bool isLocking: false

    property real outerOpacity: 1

    property real innerScale: 1.0

    property real glitchX: 0

    property real glitchOpacity: 0

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.outerOpacity
    }

    Timer {
        id: logoGlitchTimer

        interval: 48

        repeat: true

        running: root.isLocking

        onTriggered: {
            let rand = Math.random()
            if (rand > 0.8) {
                root.glitchX = (Math.random() - 0.5) * 40
                root.glitchOpacity = 0.3
            } else if (rand > 0.4) {
                root.glitchX = 0
                root.glitchOpacity = 0.15
            } else {
                root.glitchX = 0
                root.glitchOpacity = 0
            }
        }
    }

    Item {
        id: container

        anchors.centerIn: parent
        width: 300
        height: 300
        scale: 1.0
        z: 5

        Repeater {
            model: 20

            Rectangle {
                id: bit

                width: Math.random() * 6 + 2
                height: width
                color: root.accent
                opacity: 0
                visible: opacity > 0

                readonly property real angle: Math.random() * Math.PI * 2

                readonly property real distance: 100 + Math.random() * 150

                x: 150
                y: 150

                SequentialAnimation on x {
                    running: root.isLocking

                    NumberAnimation {
                        to: 150 + Math.cos(bit.angle) * bit.distance
                        duration: 600
                        easing.type: Easing.OutQuart
                    }
                }

                SequentialAnimation on y {
                    running: root.isLocking

                    NumberAnimation {
                        to: 150 + Math.sin(bit.angle) * bit.distance
                        duration: 600
                        easing.type: Easing.OutQuart
                    }
                }

                SequentialAnimation on opacity {
                    running: root.isLocking

                    NumberAnimation { 
                        to: 0.8
                        duration: 50 
                    }

                    NumberAnimation { 
                        to: 0
                        duration: 500
                        easing.type: Easing.InQuad 
                    }
                }
            }
        }

        Rectangle {
            id: outerDiamond

            anchors.centerIn: parent
            width: 180
            height: 180
            rotation: 45 + rotationAnim.angle
            color: "transparent"

            opacity: root.outerOpacity

            border {
                color: root.accent
                width: 4
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"

                border {
                    color: root.accent
                    width: 1
                }

                opacity: 0.3
                scale: 1.1
            }
        }

        Rectangle {
            id: innerDiamond

            anchors.centerIn: parent
            width: 100 * root.innerScale
            height: 100 * root.innerScale
            rotation: 45 - (rotationAnim.angle * 1.5)
            color: "transparent"

            border {
                color: root.accent
                width: {
                    return 2 / root.innerScale
                }
            }
        }
    }

    Repeater {
        model: 8

        Rectangle {
            width: 40 + (Math.random() * 160)

            height: 1

            color: root.accent

            opacity: root.glitchOpacity

            x: (root.width / 2) + (Math.random() - 0.5) * 400 - (width / 2) + root.glitchX

            y: (root.height / 2) + (Math.random() - 0.5) * 200
            
            visible: root.isLocking && opacity > 0
        }
    }

    QtObject {
        id: rotationAnim

        property real angle: 0
        
        SequentialAnimation on angle {
            id: mainTimeline

            loops: 1
            
            NumberAnimation {
                to: 240
                duration: 1200
                easing.type: Easing.InOutQuart
            }
            
            ScriptAction {
                script: {
                    root.isLocking = true
                    lockSlam.start()
                    TerminalManager.displayMessage("---ACCESSING_ENCRYPTED_NODE---")
                }
            }
        }
    }

    SequentialAnimation {
        id: lockSlam
        
        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation { 
                    target: container
                    property: "scale"
                    to: 1.3
                    duration: 100
                    easing.type: Easing.OutQuad 
                }

                NumberAnimation { 
                    target: container
                    property: "scale"
                    to: 0.95
                    duration: 150
                    easing.type: Easing.OutBack 
                }

                NumberAnimation { 
                    target: container
                    property: "scale"
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutElastic 
                }
            }
        }

        ScriptAction {
            script: {
                logoGlitchTimer.stop()
                root.glitchOpacity = 0
            }
        }

        PauseAnimation { 
            duration: 400 
        }

        ParallelAnimation {
            NumberAnimation { 
                target: root
                property: "outerOpacity"
                to: 0
                duration: 800
                easing.type: Easing.OutQuart
            }

            NumberAnimation {
                target: root
                property: "innerScale"
                to: 0.4
                duration: 800
                easing.type: Easing.OutQuart
            }
        }
        
        ScriptAction {
            script: {
                TerminalManager.displayMessage("LOGO_INTEGRITY_CHECK... [PASSED]")
                root.finished()
            }
        }
    }

    Component.onCompleted: {
        TerminalManager.displayMessage("INITIALIZING_BOOT_SEQUENCE...")
    }
}
