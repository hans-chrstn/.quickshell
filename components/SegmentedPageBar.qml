import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    required property var pages
    required property string currentPage
    signal pageSelected(string pageId)

    implicitHeight: 32
    radius: 10
    color: Qt.rgba(1, 1, 1, 0.045)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 3

        Repeater {
            model: root.pages

            HighlightableSurface {
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                interactive: true
                selected: root.currentPage === modelData.id
                baseColor: "transparent"
                cornerRadius: 7
                accessibleName: modelData.label
                onSurfaceActivated: root.pageSelected(modelData.id)

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: parent.selected ? Design.text : Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 10
                    font.weight: parent.selected ? Font.DemiBold : Font.Normal
                }
            }
        }
    }
}
