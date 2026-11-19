import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core

HighlightableSurface {
    id: root

    required property string title
    required property string description
    required property bool checked
    property bool dangerous: false
    signal activated
    signal toggled(bool newValue)

    implicitHeight: 60
    interactive: false
    focused: navigationHover.hovered
    baseColor: "transparent"
    cornerRadius: Design.radiusControl

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Design.space12
        anchors.rightMargin: Design.space8
        spacing: Design.space8

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
                        color: root.dangerous ? Theme.danger : Theme.textPrimary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeBody
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: root.description
                        color: Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeCaption
                        elide: Text.ElideRight
                    }
                }

                IslandGlyph {
                    name: "chevronRight"
                    glyphColor: navigationHover.hovered ? Theme.accent : Theme.textTertiary
                    Layout.preferredWidth: 17
                    Layout.preferredHeight: 17
                }
            }

            HoverHandler {
                id: navigationHover
            }
            TapHandler {
                onTapped: root.activated()
            }
        }

        ToggleSwitch {
            Layout.preferredWidth: 43
            Layout.preferredHeight: 25
            checked: root.checked
            activeColor: root.dangerous ? Theme.statusDanger : Theme.accent
            accessibleName: root.title
            onToggled: value => root.toggled(value)
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Design.space12
        anchors.rightMargin: Design.space12
        height: 1
        color: Theme.separator
    }
}
