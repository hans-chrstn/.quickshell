import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    property string title: ""
    property string description: ""
    property string glyph: ""
    property bool quiet: false

    radius: Design.editorSectionRadius
    color: quiet ? Qt.rgba(1, 1, 1, 0.025) : Qt.rgba(1, 1, 1, 0.045)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, quiet ? 0.045 : 0.075)

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 28, 280)
        spacing: 8

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            visible: root.glyph.length > 0
            implicitWidth: 32
            implicitHeight: 32
            radius: 10
            color: Qt.rgba(1, 1, 1, 0.06)

            Text {
                anchors.centerIn: parent
                text: root.glyph
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Design.text
            horizontalAlignment: Text.AlignHCenter
            font.family: Design.fontText
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            visible: root.description.length > 0
            text: root.description
            color: Design.textMuted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.family: Design.fontText
            font.pixelSize: 11
            lineHeight: 1.15
        }
    }
}
