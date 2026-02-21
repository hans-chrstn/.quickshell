import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.components

ScreenCorner {
    id: root
    activeTop: true
    activeRight: true
    aboveWindows: true
    hoverEnabled: true
    expandedWidth: 220
    expandedHeight: 100
    
    f1Rot: 0
    f1X: -20 - 10
    f1Y: 16
    
    f2Rot: 0
    f2X: 220 - 20 - 16 - 10
    f2Y: 100 - 1

    customTL: 0
    customTR: 0
    customBL: FrameConfig.dynamicIslandCornerRadius
    customBR: 0

    Process {
        id: recorder
        function startRecording() {
            let home = Quickshell.env("HOME") || "/tmp"
            let timestamp = new Date().getTime()
            let filename = home + "/Videos/recording_" + root.screenName + "_" + timestamp + ".mp4"
            command = ["wf-recorder", "-o", root.screenName, "-f", filename]
            running = true
            Quickshell.execDetached(["notify-send", "Recording Started", "Screen: " + root.screenName + "\nFile: " + filename])
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && exitCode !== 130) {
                Quickshell.execDetached(["notify-send", "Recorder Stopped", "Screen: " + root.screenName + "\nError code: " + exitCode])
            } else {
                Quickshell.execDetached(["notify-send", "Recording Saved", "Screen: " + root.screenName])
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 24
        
        Column {
            spacing: 6
            Rectangle {
                id: wallBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width: 44; height: 44; radius: 22; color: "white"
                opacity: wallMouse.containsMouse ? 0.2 : 0.1
                scale: wallMouse.containsMouse ? 1.05 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                Text { anchors.centerIn: parent; text: "󰸉"; color: "white"; font.pixelSize: 22 }
                MouseArea {
                    id: wallMouse; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        wallpaperWin.visible = !wallpaperWin.visible
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; text: "WALL"
                color: "white"; opacity: wallMouse.containsMouse ? 1.0 : 0.6; font.pixelSize: 9
                font.weight: Font.Bold; font.letterSpacing: 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        Column {
            spacing: 6
            Rectangle {
                id: snapBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width: 44; height: 44; radius: 22; color: "white"
                opacity: snapMouse.containsMouse ? 0.2 : 0.1
                scale: snapMouse.containsMouse ? 1.05 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                Text { anchors.centerIn: parent; text: "󰄀"; color: "white"; font.pixelSize: 22 }
                MouseArea {
                    id: snapMouse; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        Quickshell.execDetached(["niri", "msg", "action", "screenshot"])
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; text: "SNAP"
                color: "white"; opacity: snapMouse.containsMouse ? 1.0 : 0.6; font.pixelSize: 9
                font.weight: Font.Bold; font.letterSpacing: 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
        
        Column {
            spacing: 6
            Rectangle {
                id: recBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width: 44; height: 44; radius: 22
                color: recorder.running ? FrameConfig.dangerColor : "white"
                opacity: recorder.running ? 1.0 : (recMouse.containsMouse ? 0.3 : 0.1)
                scale: recMouse.containsMouse ? 1.05 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                Rectangle {
                    anchors.centerIn: parent; width: recorder.running ? 14 : 18; height: width
                    radius: recorder.running ? 3 : 9; color: "white"
                    Behavior on width { NumberAnimation { duration: 200 } }
                    Behavior on radius { NumberAnimation { duration: 200 } }
                }
                MouseArea {
                    id: recMouse; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (!recorder.running) recorder.startRecording();
                        else recorder.signal(2);
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.running ? "STOP" : "REC"
                color: recorder.running ? FrameConfig.dangerColor : "white"
                opacity: (recMouse.containsMouse || recorder.running) ? 1.0 : 0.6
                font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }
}
