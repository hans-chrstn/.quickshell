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

    property real expansion: 0

    onActiveChanged: {
        if (active) {
            introAnim.start()
        }
    }

    SequentialAnimation {
        id: introAnim

        PauseAnimation { 
            duration: 200 
        }

        NumberAnimation {
            target: root
            property: "expansion"
            to: 1
            duration: 1200
            easing.type: Easing.OutQuart
        }

        ScriptAction {
            script: {
                TerminalManager.unpause()
            }
        }
    }

    Rectangle {
        id: container

        anchors.centerIn: parent

        width: 400 * root.expansion

        height: 120 * root.expansion

        color: Qt.rgba(0, 0, 0, 0.4)

        border {
            color: ThemeManager.outlinePrimaryColor
            width: 1
        }

        clip: true

        opacity: {
            if (root.expansion > 0.01) {
                return 1
            }
            return 0
        }

        Behavior on opacity {
            NumberAnimation { duration: 400 }
        }

        Rectangle { 
            width: 8
            height: 1
            color: ThemeManager.accentColor
            z: 20
            visible: root.expansion > 0.95
            anchors { top: parent.top; left: parent.left }
        }

        Rectangle { 
            width: 1
            height: 8
            color: ThemeManager.accentColor
            z: 20
            visible: root.expansion > 0.95
            anchors { top: parent.top; left: parent.left }
        }

        Rectangle { 
            width: 8
            height: 1
            color: ThemeManager.accentColor
            z: 20
            visible: root.expansion > 0.95
            anchors { bottom: parent.bottom; right: parent.right }
        }

        Rectangle { 
            width: 1
            height: 8
            color: ThemeManager.accentColor
            z: 20
            visible: root.expansion > 0.95
            anchors { bottom: parent.bottom; right: parent.right }
        }

        TextMetrics {
            id: metrics
            font { pixelSize: 10; family: "monospace" }
            text: "-"
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

            opacity: {
                if (root.expansion > 0.9) {
                    return 1
                }
                return 0
            }

            Behavior on opacity {
                NumberAnimation { duration: 500 }
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
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.3; color: "white" }
                                GradientStop { position: 1.0; color: "white" }
                            }
                        }
                    }
                }
            }

            delegate: Item {
                width: logView.width

                height: logLabel.implicitHeight + 2
                
                property int charCount: 0

                readonly property string fullText: {
                    if (model.isHeader) {
                        let stripped = model.raw.replace(/-/g, "").trim()
                        let charWidth = metrics.advanceWidth
                        let availableWidth = logView.width - 20
                        let totalChars = Math.floor(availableWidth / charWidth)
                        let hyphens = Math.max(0, Math.floor((totalChars - stripped.length) / 2))
                        let padding = "-".repeat(hyphens)
                        return padding + stripped + padding
                    }
                    return model.message
                }

                Timer {
                    interval: 15
                    running: root.expansion > 0.9
                    repeat: true
                    onTriggered: {
                        if (charCount < fullText.length) {
                            charCount++
                        } else {
                            stop()
                        }
                    }
                }

                StyledLabel {
                    id: logLabel

                    anchors.fill: parent

                    text: {
                        let base = parent.fullText.substring(0, parent.charCount)
                        if (parent.charCount < parent.fullText.length) {
                            let symbols = ["#", "&", "*", "?", "@", "%", "$", "!"]
                            let randomSymbol = symbols[Math.floor(Math.random() * symbols.length)]
                            return base + randomSymbol
                        }
                        return base
                    }

                    font {
                        pixelSize: 10
                        family: "monospace"
                    }

                    horizontalAlignment: model.isHeader ? Text.AlignHCenter : Text.AlignLeft

                    customColor: {
                        if (model.raw.includes("failed") || model.raw.includes("FAILED")) {
                            return ThemeManager.dangerColor
                        }
                        return model.isHeader ? ThemeManager.accentColor : ThemeManager.surfaceContentColor
                    }

                    opacity: model.isHeader ? 0.8 : 0.5
                }
            }

            onCountChanged: {
                Qt.callLater(logView.positionViewAtEnd)
            }
        }
    }
}
