import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core

HighlightableSurface {
    id: root

    required property string title
    required property string description
    signal activated

    implicitHeight: 52
    interactive: false
    focused: hover.hovered
    baseColor: Theme.fillSubtle
    cornerRadius: 10

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: root.title
                color: Theme.textPrimary
                font.family: Design.fontText
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Text {
                text: root.description
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 9
            }
        }

        IslandGlyph {
            name: "chevronRight"
            glyphColor: hover.hovered ? Theme.textPrimary : Theme.textSecondary
            Layout.preferredWidth: 17
            Layout.preferredHeight: 17
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }
    }

    HoverHandler {
        id: hover
    }
    TapHandler {
        id: tap
        acceptedButtons: Qt.LeftButton
        onTapped: root.activated()
    }
}
