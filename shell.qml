//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.bars
import "components"

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: TopBar {}
    }

    Variants {
        model: Quickshell.screens
        delegate: LeftBar {}
    }

    Variants {
        model: Quickshell.screens
        delegate: RightBar {}
    }

    Variants {
        model: Quickshell.screens
        delegate: BottomBar {}
    }

    Variants {
        model: Quickshell.screens
        delegate: ScreenCorner {
            activeTop: true
            activeLeft: true
            aboveWindows: true
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: ScreenCorner {
            id: corner
            activeTop: true
            activeRight: true
            aboveWindows: true
            hoverEnabled: true
            expandedWidth: 160
            expandedHeight: 100

            Process {
                id: recorder
                function startRecording() {
                    let home = Quickshell.env("HOME") || "/tmp"
                    let timestamp = new Date().getTime()
                    let filename = home + "/Videos/recording_" + corner.screenName + "_" + timestamp + ".mp4"
                    command = ["sh", "-c", "wf-recorder -o " + corner.screenName + " -f " + filename]
                    running = true
                    Quickshell.execDetached(["notify-send", "Recording Started", "Screen: " + corner.screenName + "\nFile: " + filename])
                }
                
                onExited: (exitCode, exitStatus) => {
                    if (exitCode !== 0 && exitCode !== 130) {
                        Quickshell.execDetached(["notify-send", "Recorder Stopped", "Screen: " + corner.screenName + "\nError code: " + exitCode])
                    } else {
                        Quickshell.execDetached(["notify-send", "Recording Saved", "Screen: " + corner.screenName])
                    }
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 20

                Column {
                    spacing: 8
                    
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40; height: 40; radius: 20
                        color: "#333"
                        Text { anchors.centerIn: parent; text: "📸"; font.pixelSize: 20 }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Quickshell.execDetached(["sh", "-c", "niri msg action screenshot"])
                        }
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Snap"; color: "white"; font.pixelSize: 10 }
                }

                Column {
                    spacing: 8
                    
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40; height: 40; radius: 20
                        color: recorder.running ? "#ff4444" : "#333"
                        
                        Rectangle {
                            anchors.centerIn: parent
                            width: recorder.running ? 16 : 20
                            height: width
                            radius: recorder.running ? 4 : 10
                            color: recorder.running ? "white" : "#ff4444"
                            Behavior on width { NumberAnimation { duration: 200 } }
                            Behavior on radius { NumberAnimation { duration: 200 } }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!recorder.running) {
                                    recorder.startRecording()
                                } else {
                                    recorder.signal(2)
                                }
                            }
                        }
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: recorder.running ? "Stop" : "Rec"; color: "white"; font.pixelSize: 10 }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: ScreenCorner {
            activeBottom: true
            activeLeft: true
            aboveWindows: true
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: ScreenCorner {
            activeBottom: true
            activeRight: true
            aboveWindows: true
            hoverEnabled: true
            expandedWidth: 160
            expandedHeight: 100

            property string confirmAction: ""

            Item {
                anchors.fill: parent

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: confirmAction === ""
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Logout"
                        color: "white"
                        font.pixelSize: 14
                        MouseArea {
                            anchors.fill: parent
                            onClicked: confirmAction = "logout"
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Power Off"
                        color: "#ff5555"
                        font.pixelSize: 14
                        font.bold: true
                        MouseArea {
                            anchors.fill: parent
                            onClicked: confirmAction = "poweroff"
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: confirmAction !== ""

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Are you sure?"
                        color: "white"
                        font.pixelSize: 12
                        font.italic: true
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 15

                        Text {
                            text: "Yes"
                            color: "#ff5555"
                            font.pixelSize: 14
                            font.bold: true
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (confirmAction === "logout") {
                                        Quickshell.execDetached(["sh", "-c", "loginctl terminate-user $USER"])
                                    } else {
                                        Quickshell.execDetached(["sh", "-c", "systemctl poweroff"])
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Cancel"
                            color: "white"
                            font.pixelSize: 14
                            MouseArea {
                                anchors.fill: parent
                                onClicked: confirmAction = ""
                            }
                        }
                    }
                }
            }
            
            onExpandedStateChanged: if (!expandedState) confirmAction = ""
        }
    }
}
