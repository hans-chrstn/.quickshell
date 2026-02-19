//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import Quickshell
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
            hoverEnabled: true
            
            Text {
                anchors.centerIn: parent
                text: "Menu"
                color: "white"
                font.pixelSize: 12
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: ScreenCorner {
            activeTop: true
            activeRight: true
            aboveWindows: true
            hoverEnabled: true

            Text {
                anchors.centerIn: parent
                text: "Exit"
                color: "white"
                font.pixelSize: 12
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
            expandedWidth: 120
            expandedHeight: 80

            Column {
                anchors.centerIn: parent
                spacing: 10
                
                Text {
                    text: "Logout"
                    color: "white"
                    font.pixelSize: 14
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.run(["loginctl", "terminate-user", "$USER"])
                    }
                }

                Text {
                    text: "Power Off"
                    color: "#ff5555"
                    font.pixelSize: 14
                    font.bold: true
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.run(["systemctl", "poweroff"])
                    }
                }
            }
        }
    }
}
