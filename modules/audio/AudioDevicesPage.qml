import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.audio

Item {
    id: root

    readonly property bool showingInput: AudioPanelService.currentPage === "input"
    implicitWidth: 600
    implicitHeight: 300

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Theme.fillSubtle
        border.width: 1
        border.color: Theme.separatorQuiet

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
                accentColor: Theme.textPrimary
            }
        }
    }
}
