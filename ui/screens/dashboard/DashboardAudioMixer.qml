import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared
import "./audiomixer"

ColumnLayout {
    id: root

    property bool active: false

    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

    StyledLabel {
        text: "Audio Mixer"
        type: "heading"
        font.pixelSize: 28
    }

    ListView {
        id: streamList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: {
            if (!AudioManager) {
                return null
            }
            return AudioManager.streams
        }
        spacing: 15
        clip: true

        delegate: AudioStreamDelegate {
            streamData: model
            isActive: root.active
        }

        StyledLabel {
            text: "No active application streams"
            type: "caption"
            opacity: 0.3
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: {
                if (!AudioManager || !AudioManager.streams) {
                    return true
                }
                return AudioManager.streams.count === 0
            }
        }
    }
}
