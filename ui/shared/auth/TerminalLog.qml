import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.core
import qs.ui.shared

Item {
    id: root

    implicitWidth: 400

    implicitHeight: 120

    property bool active: false

    property real expandWidth: 0

    property real expandHeight: 0

    onActiveChanged: {
        if (active) {
            introAnim.start()
        } else {
            outroAnim.start()
        }
    }

    SequentialAnimation {
        id: introAnim

        NumberAnimation {
            target: root
            property: "expandWidth"
            to: 1
            duration: 400
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "expandHeight"
            to: 1
            duration: 500
            easing.type: Easing.OutQuart
        }

        ScriptAction {
            script: {
                TerminalManager.unpause()
            }
        }
    }

    SequentialAnimation {
        id: outroAnim

        NumberAnimation {
            target: root
            property: "expandHeight"
            to: 0
            duration: 300
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "expandWidth"
            to: 0
            duration: 300
            easing.type: Easing.InCubic
        }
    }

    Rectangle {
        id: container

        anchors.centerIn: parent

        width: 400 * root.expandWidth

        height: 120 * root.expandHeight

        color: Qt.rgba(0, 0, 0, 0.4)

        border {
            color: ThemeManager.outlinePrimaryColor
            width: 1
        }

        clip: true

        opacity: root.expandHeight > 0.1 ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Rectangle { 
            width: 8
            height: 1
            color: ThemeManager.accentColor
            z: 20
            visible: root.expandWidth > 0.9

            anchors {
                top: parent.top
                left: parent.left
            }
        }

        Rectangle { 
            width: 1
            height: 8
            color: ThemeManager.accentColor
            z: 20
            visible: root.expandHeight > 0.9

            anchors {
                top: parent.top
                left: parent.left
            }
        }

        Rectangle { 
            width: 8
            height: 1
            color: ThemeManager.accentColor
            z: 20
            visible: root.expandWidth > 0.9

            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }

        Rectangle { 
            width: 1
            height: 8
            color: ThemeManager.accentColor
            z: 20
            visible: root.expandHeight > 0.9

            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }

        ListView {
            id: logView

            anchors {
                fill: parent
                margins: 10
            }

            model: TerminalManager.logModel

            clip: true

            interactive: false

            z: 10

            opacity: root.expandHeight > 0.8 ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
            
            layer {
                enabled: true
                effect: MultiEffect {
                    maskEnabled: true
                    maskSource: ShaderEffectSource {
                        sourceItem: Rectangle {
                            width: logView.width
                            height: logView.height
                            gradient: Gradient {
                                GradientStop { 
                                    position: 0.0
                                    color: "transparent" 
                                }
                                GradientStop { 
                                    position: 0.3
                                    color: "white" 
                                }
                                GradientStop { 
                                    position: 1.0
                                    color: "white" 
                                }
                            }
                        }
                    }
                }
            }

            delegate: Item {
                width: logView.width

                height: logLabel.implicitHeight + 2
                
                readonly property string processedText: {
                    let txt = model.raw
                    if (txt.startsWith("---")) {
                        let stripped = txt.replace(/-/g, "").trim()
                        return stripped
                    }
                    return model.message
                }

                StyledLabel {
                    id: logLabel

                    anchors.fill: parent

                    text: parent.processedText

                    font {
                        pixelSize: 10
                        family: "monospace"
                    }

                    horizontalAlignment: {
                        if (model.raw.startsWith("---")) {
                            return Text.AlignHCenter
                        }
                        return Text.AlignLeft
                    }

                    customColor: {
                        if (model.raw.includes("failed") || model.raw.includes("FAILED")) {
                            return ThemeManager.dangerColor
                        }
                        if (model.raw.startsWith("---")) {
                            return ThemeManager.accentColor
                        }
                        return ThemeManager.surfaceContentColor
                    }

                    opacity: {
                        if (model.raw.startsWith("---")) {
                            return 0.8
                        }
                        return 0.5
                    }
                }
            }

            onCountChanged: {
                Qt.callLater(logView.positionViewAtEnd)
            }

            add: Transition {
                SequentialAnimation {
                    NumberAnimation { 
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 50 
                    }
                    NumberAnimation { 
                        property: "opacity"
                        from: 1
                        to: 0.3
                        duration: 50 
                    }
                    NumberAnimation { 
                        property: "opacity"
                        from: 0.3
                        to: 0.6
                        duration: 100 
                    }
                    NumberAnimation { 
                        property: "x"
                        from: -10
                        to: 0
                        duration: 100 
                    }
                }
            }
        }
    }
}
