//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.bars
import qs.components
import qs.config

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: TopBar {
            aboveWindows: true
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LeftBar {
            aboveWindows: true
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: RightBar {
            aboveWindows: true
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: BottomBar {
            aboveWindows: true
        }
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
                    command = ["wf-recorder", "-o", corner.screenName, "-f", filename]
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
                spacing: 24

                Column {
                    spacing: 6
                    
                    Rectangle {
                        id: snapBtn
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 44; height: 44; radius: 22
                        color: "white"
                        opacity: snapMouse.containsMouse ? 0.2 : 0.1
                        scale: snapMouse.containsMouse ? 1.05 : 1.0
                        
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        
                        Text { anchors.centerIn: parent; text: "󰄀"; color: "white"; font.pixelSize: 22 }
                        
                        MouseArea {
                            id: snapMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(["niri", "msg", "action", "screenshot"])
                        }
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "SNAP"; color: "white"; opacity: snapMouse.containsMouse ? 1.0 : 0.6; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1; Behavior on opacity { NumberAnimation { duration: 200 } } }
                }

                Column {
                    spacing: 6
                    
                    Rectangle {
                        id: recBtn
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 44; height: 44; radius: 22
                        color: recorder.running ? FrameConfig.dangerColor : "white"
                        opacity: (recMouse.containsMouse || recorder.running) ? 1.0 : 0.1
                        scale: recMouse.containsMouse ? 1.05 : 1.0
                        
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        
                        Rectangle {
                            anchors.centerIn: parent
                            width: recorder.running ? 14 : 18
                            height: width
                            radius: recorder.running ? 3 : 9
                            color: "white"
                            Behavior on width { NumberAnimation { duration: 200 } }
                            Behavior on radius { NumberAnimation { duration: 200 } }
                        }
                        
                        MouseArea {
                            id: recMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (!recorder.running) {
                                    recorder.startRecording()
                                } else {
                                    recorder.signal(2)
                                }
                            }
                        }
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: recorder.running ? "STOP" : "REC"; color: recorder.running ? FrameConfig.dangerColor : "white"; opacity: (recMouse.containsMouse || recorder.running) ? 1.0 : 0.6; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1; Behavior on opacity { NumberAnimation { duration: 200 } } }
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
                    spacing: 8
                    visible: confirmAction === ""
                    
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 100; height: 32; radius: 16
                        color: "white"
                        opacity: logoutMouse.containsMouse ? 0.2 : 0.1
                        scale: logoutMouse.containsMouse ? 1.02 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 200 } }

                        Text {
                            anchors.centerIn: parent
                            text: "LOGOUT"
                            color: "white"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 1
                        }
                        MouseArea {
                            id: logoutMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: confirmAction = "logout"
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 100; height: 32; radius: 16
                        color: FrameConfig.dangerColor
                        opacity: pwrMouse.containsMouse ? 0.3 : 0.2
                        scale: pwrMouse.containsMouse ? 1.02 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 200 } }

                        Text {
                            anchors.centerIn: parent
                            text: "POWER OFF"
                            color: FrameConfig.dangerColor
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 1
                        }
                        MouseArea {
                            id: pwrMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: confirmAction = "poweroff"
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: confirmAction !== ""

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "CONFIRM ACTION?"
                        color: "white"
                        opacity: 0.6
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        Rectangle {
                            width: 60; height: 32; radius: 16
                            color: FrameConfig.dangerColor
                            Text {
                                anchors.centerIn: parent
                                text: "YES"
                                color: "white"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (confirmAction === "logout") {
                                        Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")])
                                    } else {
                                        Quickshell.execDetached(["systemctl", "poweroff"])
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 60; height: 32; radius: 16
                            color: "white"; opacity: 0.1
                            Text {
                                anchors.centerIn: parent
                                text: "NO"
                                color: "white"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
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
