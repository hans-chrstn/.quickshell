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
    
    readonly property int activeButtons: {
        let count = 0;
        if (ThemeManager.showCornerWallpaper) count++;
        if (ThemeManager.showCornerSnap) count++;
        if (ThemeManager.showCornerRecord) count++;
        if (ThemeManager.showCornerTasks) count++;
        if (ThemeManager.showCornerNotes) count++;
        return count;
    }

    expandedWidth: Math.max(80, activeButtons * 70)
    expandedHeight: 100
    
    firstFilletRotation: 0
    firstFilletX: -20 - 10
    firstFilletY: 16
    
    secondFilletRotation: 0
    secondFilletX: expandedWidth - 20 - 16 - 10
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
        spacing: 20
        
        Column {
            spacing: 6
            visible: ThemeManager.showCornerWallpaper
            BaseButton {
                id: wallBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width: 44; height: 44
                onClicked: ViewManager.toggleWallpaper()
                
                Rectangle {
                    anchors.fill: parent; radius: 22; color: "white"
                    opacity: wallBtn.isHovered ? 0.2 : 0.1
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    StyledLabel { anchors.centerIn: parent; text: "󰸉"; type: "icon"; font.pixelSize: 22 }
                }
            }
            StyledLabel {
                anchors.horizontalCenter: parent.horizontalCenter; text: "WALL"
                type: "caption"; opacity: wallBtn.isHovered ? 1.0 : 0.6; font.weight: Font.Bold; font.letterSpacing: 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        Column {
            spacing: 6
            visible: ThemeManager.showCornerSnap
            BaseButton {
                id: snapBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width: 44; height: 44
                onClicked: Quickshell.execDetached(["niri", "msg", "action", "screenshot"])
                
                Rectangle {
                    anchors.fill: parent; radius: 22; color: "white"
                    opacity: snapBtn.isHovered ? 0.2 : 0.1
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    StyledLabel { anchors.centerIn: parent; text: "󰄀"; type: "icon"; font.pixelSize: 22 }
                }
            }
            StyledLabel {
                anchors.horizontalCenter: parent.horizontalCenter; text: "SNAP"
                type: "caption"; opacity: snapBtn.isHovered ? 1.0 : 0.6; font.weight: Font.Bold; font.letterSpacing: 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
        
        Column {
            spacing: 6
            visible: ThemeManager.showCornerRecord
            BaseButton {
                id: recBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width: 44; height: 44
                onClicked: {
                    if (!recorder.running) recorder.startRecording();
                    else recorder.signal(2);
                }
                
                Rectangle {
                    anchors.fill: parent; radius: 22
                    color: recorder.running ? ThemeManager.dangerColor : "white"
                    opacity: recorder.running ? 1.0 : (recBtn.isHovered ? 0.3 : 0.1)
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                    
                    Rectangle {
                        anchors.centerIn: parent; width: recorder.running ? 14 : 18; height: width
                        radius: recorder.running ? 3 : 9; color: "white"
                        Behavior on width { NumberAnimation { duration: 200 } }
                        Behavior on radius { NumberAnimation { duration: 200 } }
                    }
                }
            }
            StyledLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.running ? "STOP" : "REC"
                type: "caption"
                customColor: recorder.running ? ThemeManager.dangerColor : "white"
                opacity: (recBtn.isHovered || recorder.running) ? 1.0 : 0.6
                font.weight: Font.Bold; font.letterSpacing: 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        Column {
            spacing: 6
            visible: ThemeManager.showCornerTasks
            BaseButton {
                id: taskBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width: 44; height: 44
                onClicked: ViewManager.toggleTaskManager()
                
                Rectangle {
                    anchors.fill: parent; radius: 22; color: "white"
                    opacity: taskBtn.isHovered ? 0.2 : 0.1
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    StyledLabel { anchors.centerIn: parent; text: "󰍛"; type: "icon"; font.pixelSize: 22 }
                }
            }
            StyledLabel {
                anchors.horizontalCenter: parent.horizontalCenter; text: "TASKS"
                type: "caption"; opacity: taskBtn.isHovered ? 1.0 : 0.6; font.weight: Font.Bold; font.letterSpacing: 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        Column {
            spacing: 6
            visible: ThemeManager.showCornerNotes
            BaseButton {
                id: notesBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width: 44; height: 44
                onClicked: ViewManager.toggleNotes()
                
                Rectangle {
                    anchors.fill: parent; radius: 22; color: "white"
                    opacity: notesBtn.isHovered ? 0.2 : 0.1
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    StyledLabel { anchors.centerIn: parent; text: "󰠮"; type: "icon"; font.pixelSize: 22 }
                }
            }
            StyledLabel {
                anchors.horizontalCenter: parent.horizontalCenter; text: "NOTES"
                type: "caption"; opacity: notesBtn.isHovered ? 1.0 : 0.6; font.weight: Font.Bold; font.letterSpacing: 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }
}
