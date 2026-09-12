import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core

Rectangle {
    id: root

    required property string title
    required property string description
    required property bool checked
    property bool dangerous: false
    signal activated()
    signal toggled(bool newValue)

    implicitHeight: 52
    radius: 10
    color: navigationHover.hovered ? Design.surfaceRaised : Design.surface
    border.width: 1
    border.color: navigationHover.hovered
        ? Design.glassHighlight : Design.separator

    Behavior on color { ColorAnimation { duration: 110 } }
    Behavior on border.color { ColorAnimation { duration: 110 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 10

        Item {
            id: navigationArea
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: root.title
                        color: root.dangerous ? Design.red : Design.text
                        font.family: Design.fontText
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: root.description
                        color: Design.textMuted
                        font.family: Design.fontText
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                IslandGlyph {
                    name: "chevronRight"
                    glyphColor: navigationHover.hovered
                        ? Design.text : Design.textMuted
                    Layout.preferredWidth: 17
                    Layout.preferredHeight: 17
                }
            }

            HoverHandler { id: navigationHover }
            TapHandler { onTapped: root.activated() }
        }

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 20
            radius: 10
            color: root.checked ? Design.blue : Design.surfaceRaised
            border.width: 1
            border.color: Design.separator

            Behavior on color { ColorAnimation { duration: 120 } }

            Rectangle {
                x: root.checked ? parent.width - width - 2 : 2
                y: 2
                width: 16
                height: 16
                radius: 8
                color: Design.text
                Behavior on x {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
            }

            TapHandler { onTapped: root.toggled(!root.checked) }
        }
    }
}
