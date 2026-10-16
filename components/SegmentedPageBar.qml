import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    required property var pages
    required property string currentPage
    property color accentColor: Design.blue
    property real controlHeight: 32
    property real cornerRadius: 10
    property real labelPixelSize: 10
    signal pageSelected(string pageId)

    implicitHeight: controlHeight
    radius: cornerRadius
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
                accentColor: root.accentColor
                baseColor: "transparent"
                cornerRadius: Math.max(6, root.cornerRadius - 3)
                accessibleName: modelData.label
                onSurfaceActivated: root.pageSelected(modelData.id)

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: parent.selected ? Design.text : Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: root.labelPixelSize
                    font.weight: parent.selected ? Font.DemiBold : Font.Normal
                }
            }
        }
    }
}
