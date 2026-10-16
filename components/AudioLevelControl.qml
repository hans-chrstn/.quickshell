import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.core

Item {
    id: root

    required property string title
    required property string subtitle
    required property string glyph
    required property real value
    required property real maximumValue
    required property bool muted
    property bool available: true
    property color accentColor: Design.blue
    readonly property bool amplified: !muted && value > 1.0001
    readonly property color effectiveAccent: muted ? Design.textMuted : amplified ? Design.yellow : accentColor
    signal valueEdited(real value)
    signal muteRequested(bool muted)
    signal stepRequested(int steps)

    implicitWidth: 616
    implicitHeight: 126
    opacity: available ? 1 : 0.46

    Accessible.name: title + " volume"
    Accessible.description: subtitle

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.topMargin: 17
        anchors.bottomMargin: 17
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: root.title
                color: Design.text
                font.family: Design.fontText
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.available ? root.subtitle : "Unavailable"
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 12
                elide: Text.ElideMiddle
            }

            Text {
                text: root.muted ? "Muted" : Math.max(0, Math.round(root.value * 100)) + "%"
                color: root.effectiveAccent
                font.family: Design.fontMono
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            GlyphButton {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                glyphSize: 24
                enabled: root.available
                glyph: root.glyph
                accessibleName: (root.muted ? "Unmute " : "Mute ") + root.title.toLowerCase()
                primary: root.muted
                accentColor: root.muted ? Design.red : root.accentColor
                onActivated: root.muteRequested(!root.muted)
            }

            Slider {
                id: levelSlider

                Layout.fillWidth: true
                Layout.preferredHeight: 42
                enabled: root.available
                from: 0
                to: Math.max(0.01, root.maximumValue)
                stepSize: 0.01
                value: Math.max(from, Math.min(to, root.value))
                Accessible.name: root.title + " level"
                onMoved: root.valueEdited(value)

                background: Rectangle {
                    x: levelSlider.leftPadding
                    y: levelSlider.topPadding + levelSlider.availableHeight / 2 - height / 2
                    width: levelSlider.availableWidth
                    height: 10
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.10)

                    Rectangle {
                        width: levelSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: root.effectiveAccent

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }
                }

                handle: Rectangle {
                    x: levelSlider.leftPadding + levelSlider.visualPosition * (levelSlider.availableWidth - width)
                    y: levelSlider.topPadding + levelSlider.availableHeight / 2 - height / 2
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: width / 2
                    color: Design.text
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.24)
                    scale: levelSlider.pressed ? 1.14 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: 90
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                WheelHandler {
                    enabled: root.available
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                        if (delta !== 0)
                            root.stepRequested(delta > 0 ? 1 : -1);
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
