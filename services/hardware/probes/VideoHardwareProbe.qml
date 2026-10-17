import QtQuick
import QtMultimedia
import Quickshell

ShellRoot {
    Item {
        width: 2
        height: 2

        VideoOutput {
            id: output
            anchors.fill: parent
        }

        MediaPlayer {
            source: Quickshell.env("QS_CODEC_PROBE_URL") || ""
            videoOutput: output
            loops: MediaPlayer.Infinite
            Component.onCompleted: play()
        }
    }
}
