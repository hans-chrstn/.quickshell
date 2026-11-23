import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core

HighlightableSurface {
    id: root

    required property string title
    required property string description
    signal activated

    implicitHeight: 59
    interactive: true
    baseColor: "transparent"
    cornerRadius: Design.radiusControl
    accessibleName: title + ", " + description
    onSurfaceActivated: root.activated()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Design.space12
        anchors.rightMargin: Design.space8
        spacing: Design.space8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: root.title
                color: Theme.textPrimary
                font.family: Design.fontText
                font.pixelSize: Design.typeBody
                font.weight: Font.DemiBold
            }

            Text {
                text: root.description
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeLabel
                elide: Text.ElideRight
            }
        }

        IslandGlyph {
            id: arrow
            name: "chevronRight"
            glyphColor: root.hovered ? Theme.accent : Theme.textTertiary
            Layout.preferredWidth: 17
            Layout.preferredHeight: 17
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            opacity: root.hovered ? 1 : 0.65
            transform: Translate {
                x: root.hovered && !Design.reducedMotion ? 3 : 0

                Behavior on x {
                    SpatialSpring {
                        phase: "morph"
                    }
                }
            }
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
