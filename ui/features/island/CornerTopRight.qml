import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.shared

CornerContainer {
    id: root
    isAtTop: true
    isAtRight: true
    aboveWindows: true
    isHoverEnabled: true
    expandedWidth: 220
    expandedHeight: 100
    
    firstFilletRotation: 0
    firstFilletX: -20 - 10
    firstFilletY: 16
    
    secondFilletRotation: 0
    secondFilletX: 220 - 20 - 16 - 10
    secondFilletY: 100 - 1

    customTopLeftRadius: 0
    customTopRightRadius: 0
    customBottomLeftRadius: ThemeManager.dynamicIslandCornerRadius
    customBottomRightRadius: 0

    Process {
        id: recorder
        function startRecording() {
            let home = Quickshell.env("HOME") || "/tmp"
            let timestamp = new Date().getTime()
            let filename = home + "/Videos/recording_" + root.screenIdentifier + "_" + timestamp + ".mp4"
            command = ["wf-recorder", "-a", "-o", root.screenIdentifier, "-f", filename]
            running = true
            Quickshell.execDetached(["notify-send", "Recording Started", "Screen: " + root.screenIdentifier + "\nFile: " + filename])
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && exitCode !== 130) {
                Quickshell.execDetached(["notify-send", "Recorder Stopped", "Screen: " + root.screenIdentifier + "\nError code: " + exitCode])
            } else {
                Quickshell.execDetached(["notify-send", "Recording Saved", "Screen: " + root.screenIdentifier])
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
                        ViewManager.toggleWallpaper()
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
                color: recorder.running ? ThemeManager.dangerColor : "white"
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
                color: recorder.running ? ThemeManager.dangerColor : "white"
                opacity: (recMouse.containsMouse || recorder.running) ? 1.0 : 0.6
                font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }
}
