import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.time

Item {
    id: root

    property real expansionProgress: 0
    readonly property real progress: Math.max(0, Math.min(1,
        expansionProgress))
    readonly property real collapsedImplicitWidth:
        contentRow.implicitWidth * 0.58
    readonly property real collapsedImplicitHeight:
        contentRow.implicitHeight * 0.58
    readonly property real expandedImplicitWidth: contentRow.implicitWidth
    readonly property real expandedImplicitHeight: contentRow.implicitHeight

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 22
        scale: 0.58 + 0.42 * root.progress
        transformOrigin: Item.Center

        ColumnLayout {
            spacing: 0

            Text {
                text: Qt.formatDateTime(ClockService.now, "dddd")
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 11
                font.capitalization: Font.Capitalize
            }

            Text {
                text: Qt.formatDateTime(ClockService.now, "d MMMM")
                color: Design.text
                font.family: Design.fontDisplay
                font.pixelSize: 15
                font.weight: Font.DemiBold
                font.capitalization: Font.Capitalize
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter
            color: Design.separator
        }

        Text {
            text: Qt.formatDateTime(ClockService.now, "hh:mm")
            color: Design.text
            font.family: Design.fontDisplay
            font.pixelSize: 30
            font.weight: Font.Light
        }
    }
}
