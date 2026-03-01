import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.shared

Column {
    id: root
    
    spacing: 6
    
    property string screenIdentifier: ""
    
    Process {
        id: recorder
        function startRecording() {
            let home = Quickshell.env("HOME") || "/tmp"
            let timestamp = new Date().getTime()
            let filename = home + "/Videos/recording_" + root.screenIdentifier + "_" + timestamp + ".mp4"
            command = ["wf-recorder", "-a", "-o", root.screenIdentifier, "-f", filename]
            running = true
            Quickshell.execDetached(["notify-send", "Recording Started", "Screen: " + root.screenIdentifier + "
File: " + filename])
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && exitCode !== 130) {
                Quickshell.execDetached(["notify-send", "Recorder Stopped", "Screen: " + root.screenIdentifier + "
Error code: " + exitCode])
            } else {
                Quickshell.execDetached(["notify-send", "Recording Saved", "Screen: " + root.screenIdentifier])
            }
        }
    }

    BaseButton {
        id: recBtn
        anchors.horizontalCenter: parent.horizontalCenter
        width: 44
        height: 44
        onClicked: {
            if (!recorder.running) {
                recorder.startRecording()
            } else {
                recorder.signal(2)
            }
        }
        
        Rectangle {
            anchors.fill: parent
            radius: 22
            color: recorder.running ? ThemeManager.dangerColor : "white"
            opacity: recorder.running ? 1.0 : (recBtn.isHovered ? 0.3 : 0.1)
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
            
            Rectangle {
                anchors.centerIn: parent
                width: recorder.running ? 14 : 18
                height: width
                radius: recorder.running ? 3 : 9
                color: "white"
                Behavior on width {
                    NumberAnimation {
                        duration: 200
                    }
                }
                Behavior on radius {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }
        }
    }
    
    StyledLabel {
        anchors.horizontalCenter: parent.horizontalCenter
        text: recorder.running ? "STOP" : "REC"
        type: "caption"
        customColor: recorder.running ? ThemeManager.dangerColor : "white"
        opacity: (recBtn.isHovered || recorder.running) ? 1.0 : 0.6
        font.weight: Font.Bold
        font.letterSpacing: 1
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
    }
}
