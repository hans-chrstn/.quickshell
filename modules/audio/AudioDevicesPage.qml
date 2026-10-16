import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.audio

Item {
    id: root

    readonly property bool showingInput: AudioPanelService.currentPage === "input"
    implicitWidth: 640
    implicitHeight: 356

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Design.surface
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 0

            AudioDeviceList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                role: root.showingInput ? "input-device" : "output-device"
                title: root.showingInput ? "Input devices" : "Output devices"
                glyph: root.showingInput ? "microphone" : "volumeHigh"
                accentColor: Design.blue
            }
        }
    }
}
