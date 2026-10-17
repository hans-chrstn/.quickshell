import QtQuick
import qs.core
import qs.services.audio
import "../../services/audio/AudioApplicationModel.js" as AudioApplicationModel

Item {
    id: root

    readonly property var rows: AudioApplicationModel.listRows(AudioService.applications)

    implicitWidth: 600
    implicitHeight: 300

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: Theme.fillSubtle
        border.width: 1
        border.color: Theme.separatorQuiet

        Text {
            anchors.centerIn: parent
            visible: root.rows.length === 0
            text: AudioService.inventoryLoaded ? "No active audio applications" : "Discovering applications…"
            color: Theme.textTertiary
            font.family: Design.fontText
            font.pixelSize: 11
        }

        AudioApplicationList {
            anchors.fill: parent
            anchors.margins: 12
            visible: root.rows.length > 0
            rows: root.rows
        }
    }
}
