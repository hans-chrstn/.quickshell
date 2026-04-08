import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.core
import qs.ui.shared

Rectangle {
    id: root
    implicitWidth: 400
    implicitHeight: 120
    color: Qt.rgba(0, 0, 0, 0.4)
    border.color: ThemeManager.outlinePrimaryColor
    border.width: 1
    clip: true

    Rectangle { 
        width: 8
        height: 1
        color: ThemeManager.accentColor
        anchors {
            top: parent.top
            left: parent.left
        }
    }

    Rectangle { 
        width: 1
        height: 8
        color: ThemeManager.accentColor
        anchors {
            top: parent.top
            left: parent.left
        }
    }

    Rectangle { 
        width: 8
        height: 1
        color: ThemeManager.accentColor
        anchors {
            bottom: parent.bottom
            right: parent.right
        }
    }

    Rectangle { 
        width: 1
        height: 8
        color: ThemeManager.accentColor
        anchors {
            bottom: parent.bottom
            right: parent.right
        }
    }

    TextMetrics {
        id: metrics
        font {
            pixelSize: 10
            family: "monospace"
        }
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
        
        layer.enabled: true
        layer.effect: MultiEffect {
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

        delegate: Item {
            width: logView.width
            height: logLabel.implicitHeight + 2
            
            readonly property string processedText: {
                let txt = model.raw
                if (txt.startsWith("---")) {
                    let stripped = txt.replace(/-/g, "").trim()
                    let charWidth = metrics.advanceWidth
                    let availableWidth = logView.width - 40
                    let totalChars = Math.floor(availableWidth / charWidth)
                    let hyphens = Math.max(0, Math.floor((totalChars - stripped.length) / 2))
                    let padding = "-".repeat(hyphens)
                    return padding + stripped + padding
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
                horizontalAlignment: model.raw.startsWith("---") ? Text.AlignHCenter : Text.AlignLeft
                customColor: {
                    if (model.raw.includes("failed") || model.raw.includes("FAILED")) {
                        return ThemeManager.dangerColor
                    }
                    return model.raw.startsWith("---") ? ThemeManager.accentColor : ThemeManager.surfaceContentColor
                }
                opacity: model.raw.startsWith("---") ? 0.8 : 0.5
            }
        }

        onCountChanged: {
            Qt.callLater(logView.positionViewAtEnd)
        }

        add: Transition {
            SequentialAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 50 }
                NumberAnimation { property: "opacity"; from: 1; to: 0.3; duration: 50 }
                NumberAnimation { property: "opacity"; from: 0.3; to: 0.6; duration: 100 }
                NumberAnimation { property: "x"; from: -10; to: 0; duration: 100 }
            }
        }
    }
}
