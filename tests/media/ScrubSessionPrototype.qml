import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property string sourcePath: "/home/jin/.wallpapers/black-hole-event-horizon-space-4k-live-wallpaper.mp4"
    property int targetPositionMs: 0
    property int seekRequests: 0
    property int appliedSeeks: 0

    anchors.top: true
    anchors.left: true
    implicitWidth: 900
    implicitHeight: 560
    color: "#101014"
    WlrLayershell.namespace: "inspire-scrub-prototype"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    VideoOutput {
        id: output
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: scrubRail.top; margins: 20 }
        fillMode: VideoOutput.PreserveAspectFit
    }

    MediaPlayer {
        id: player
        source: "file://" + root.sourcePath
        videoOutput: output
        onMediaStatusChanged: if (mediaStatus === MediaPlayer.LoadedMedia) pause()
    }

    Rectangle {
        id: scrubRail
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 28 }
        height: 8
        radius: 4
        color: "#30303a"

        Rectangle {
            width: scrubRail.width * (root.targetPositionMs / Math.max(1, player.duration))
            height: parent.height
            radius: 4
            color: "#7aa2f7"
        }

        MouseArea {
            anchors.fill: parent
            onPressed: root.setTarget(mouse.x)
            onPositionChanged: if (pressed) root.setTarget(mouse.x)
        }
    }

    Text {
        anchors { left: parent.left; top: parent.top; margins: 20 }
        text: "Persistent scrub prototype  •  seeks: " + root.appliedSeeks
        color: "white"
        font.pixelSize: 12
    }

    Timer {
        id: seekTimer
        interval: 80
        repeat: true
        running: true
        onTriggered: {
            if (root.seekRequests <= root.appliedSeeks || player.duration <= 0)
                return
            player.position = root.targetPositionMs
            root.appliedSeeks = root.seekRequests
        }
    }

    function setTarget(x) {
        root.targetPositionMs = Math.max(0, Math.min(player.duration,
            Math.round((x / scrubRail.width) * player.duration)))
        root.seekRequests += 1
    }
}
