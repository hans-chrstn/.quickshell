import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared
import "./timer"

ColumnLayout {
    id: root

    property bool active: false
    property var chronoEngine: null
    property string activeTab: "timer"

    readonly property int targetIndex: {
        let tabs = [
            "timer", 
            "pomo", 
            "swatch", 
            "alarms", 
            "world"
        ]
        
        return Math.max(
            0, 
            tabs.indexOf(root.activeTab)
        )
    }

    anchors.fill: parent
    anchors.margins: 25
    spacing: 15

    Item {
        Layout.fillWidth: true
        height: 40

        SelectionPill {
            id: selectionIndicator
            width: (parent.width - (8 * 4)) / 5
            height: parent.height
            radius: 10
            x: root.targetIndex * (width + 8)
        }

        RowLayout {
            anchors.fill: parent
            spacing: 8
            z: 1

            Repeater {
                model: [
                    { id: "timer", icon: "󰔛" },
                    { id: "pomo", icon: "󰄉" },
                    { id: "swatch", icon: "󱎫" },
                    { id: "alarms", icon: "󰥔" },
                    { id: "world", icon: "󰆤" }
                ]

                delegate: BaseButton {
                    Layout.fillWidth: true
                    height: 40 
                    cornerRadius: 10

                    onClicked: { 
                        root.activeTab = modelData.id
                        SoundManager.playClick() 
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.pixelSize: 18
                        color: {
                            if (root.activeTab === modelData.id) {
                                return ThemeManager.contentPrimaryColor
                            }
                            return ThemeManager.contentOnBackgroundColor
                        }
                        opacity: {
                            if (root.activeTab === modelData.id) {
                                return 1.0
                            }
                            return 0.5
                        }

                        Behavior on color { 
                            ColorAnimation { 
                                duration: 200 
                            } 
                        }
                    }
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        Repeater {
            model: [
                { id: "timer", comp: timerComp },
                { id: "pomo", comp: pomoComp },
                { id: "swatch", comp: swatchComp },
                { id: "alarms", comp: alarmComp },
                { id: "world", comp: worldComp }
            ]

            delegate: Loader {
                anchors.fill: parent
                active: {
                    return root.activeTab === modelData.id || opacity > 0.01
                }
                opacity: {
                    return root.activeTab === modelData.id ? 1.0 : 0.0
                }
                visible: {
                    return opacity > 0.01
                }
                sourceComponent: modelData.comp

                Behavior on opacity { 
                    NumberAnimation { 
                        duration: 300 
                    } 
                }

                transform: Translate {
                    x: {
                        if (root.activeTab === modelData.id) {
                            return 0
                        }
                        let idxMap = {
                            "timer": 0, 
                            "pomo": 1, 
                            "swatch": 2, 
                            "alarms": 3, 
                            "world": 4
                        }
                        return root.targetIndex > idxMap[modelData.id] ? -40 : 40
                    }

                    Behavior on x { 
                        NumberAnimation { 
                            duration: 400
                            easing.type: Easing.OutExpo 
                        } 
                    }
                }
            }
        }
    }

    Component {
        id: timerComp
        TimerModule {
            chronoEngine: root.chronoEngine
        }
    }

    Component {
        id: pomoComp
        PomodoroModule {
            chronoEngine: root.chronoEngine
        }
    }

    Component {
        id: swatchComp
        StopwatchModule {
            chronoEngine: root.chronoEngine
        }
    }

    Component {
        id: alarmComp
        AlarmModule {
            chronoEngine: root.chronoEngine
        }
    }

    Component {
        id: worldComp
        WorldClockModule {
            chronoEngine: root.chronoEngine
        }
    }
}
