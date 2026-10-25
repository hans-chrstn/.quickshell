import QtQuick
import qs.core
import qs.components

Item {
    id: root

    required property string icon
    required property string label
    property color accent: Theme.textSecondary
    signal activated

    implicitWidth: 94
    implicitHeight: 32

    scale: tap.pressed ? 0.96 : (hover.hovered ? 1.015 : 1)

    Behavior on scale {
        NumberAnimation {
            duration: 110
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: tap.pressed ? Theme.controlPressed : (hover.hovered ? Theme.controlHover : Theme.controlFill)
        border.width: 1
        border.color: hover.hovered ? Theme.separatorStrong : Theme.separator

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 7

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 23
            height: 23
            radius: 8
            color: tap.pressed ? Theme.tintPressed(root.accent) : (hover.hovered ? Theme.tintHover(root.accent) : Theme.tintActive(root.accent))

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            IslandGlyph {
                anchors.centerIn: parent
                name: root.icon
                glyphColor: hover.hovered ? Theme.textPrimary : root.accent
                scale: tap.pressed ? 0.9 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: 90
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: hover.hovered ? Theme.textPrimary : Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }

    HoverHandler {
        id: hover
    }
    TapHandler {
        id: tap
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.DragThreshold
        grabPermissions: PointerHandler.ApprovesTakeOverByAnything
        onTapped: root.activated()
    }
}
