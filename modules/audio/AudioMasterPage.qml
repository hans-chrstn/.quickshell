import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services.audio

Item {
    id: root

    readonly property var output: AudioService.output
    readonly property var input: AudioService.input
    readonly property var policy: AudioService.controlPolicy

    implicitWidth: 600
    implicitHeight: 300

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: controlRows.implicitHeight + 24
        radius: 22
        color: Theme.fillSubtle
        border.width: 1
        border.color: Theme.separatorQuiet

        ColumnLayout {
            id: controlRows
            anchors.fill: parent
            anchors.margins: 12
            spacing: 0

            AudioLevelControl {
                Layout.fillWidth: true
                title: "Output"
                subtitle: String(root.output?.name || "Default output")
                glyph: root.output?.muted ? "volumeMuted" : (Number(root.output?.volume) || 0) > 0.45 ? "volumeHigh" : "volumeLow"
                value: Number(root.output?.volume) || 0
                maximumValue: Number(root.policy?.outputCeiling) || 1
                muted: root.output?.muted ?? false
                available: root.output?.available ?? false
                accentColor: Theme.textPrimary
                onValueEdited: value => AudioService.setMasterVolume("output", value)
                onMuteRequested: muted => AudioService.setMasterMuted("output", muted)
                onStepRequested: steps => AudioService.adjustMasterVolume("output", steps)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.preferredHeight: 1
                color: Theme.separator
                opacity: 0.72
            }

            AudioLevelControl {
                Layout.fillWidth: true
                title: "Input"
                subtitle: String(root.input?.name || "Default input")
                glyph: root.input?.muted ? "microphoneMuted" : "microphone"
                value: Number(root.input?.volume) || 0
                maximumValue: Number(root.policy?.inputCeiling) || 1
                muted: root.input?.muted ?? false
                available: root.input?.available ?? false
                accentColor: Theme.textPrimary
                onValueEdited: value => AudioService.setMasterVolume("input", value)
                onMuteRequested: muted => AudioService.setMasterMuted("input", muted)
                onStepRequested: steps => AudioService.adjustMasterVolume("input", steps)
            }
        }
    }
}
