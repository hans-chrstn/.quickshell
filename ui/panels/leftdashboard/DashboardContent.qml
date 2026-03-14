import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared
import qs.ui.screens.dashboard

Item {
    id: contentRoot

    property bool active: false
    property var chronoEngine: null

    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true

    readonly property int currentIndex: {
        if (!root) {
            return 0
        }
        return root.currentPage
    }

    Repeater {
        model: {
            if (!root || !root.pages) {
                return 0
            }
            return root.pages.length
        }

        delegate: Loader {
            anchors.fill: parent

            active: {
                return contentRoot.currentIndex === index || opacity > 0.01
            }

            opacity: {
                if (contentRoot.currentIndex === index) {
                    return 1.0
                }
                return 0.0
            }

            visible: {
                return opacity > 0.01
            }

            sourceComponent: {
                if (index === 0) {
                    return calendarComponent
                }
                if (index === 1) {
                    return timerComponent
                }
                if (index === 2) {
                    return tasksComponent
                }
                if (index === 3) {
                    return mixerComponent
                }
                if (index === 4) {
                    return clipboardComponent
                }
                if (index === 5) {
                    return scratchpadComponent
                }
                return null
            }

            Binding {
                target: item
                property: "active"
                value: contentRoot.active
            }

            Binding {
                target: item
                property: "chronoEngine"
                value: contentRoot.chronoEngine
                when: {
                    return index === 1 || index === 2
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: ThemeManager.animationDuration
                    easing.type: Easing.OutQuart
                }
            }

            transform: Translate {
                x: {
                    if (contentRoot.currentIndex === index) {
                        return 0
                    }
                    if (contentRoot.currentIndex > index) {
                        return -30
                    }
                    return 30
                }

                Behavior on x {
                    NumberAnimation {
                        duration: ThemeManager.animationDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }
        }
    }

    Component {
        id: calendarComponent
        DashboardCalendar {
        }
    }

    Component {
        id: timerComponent
        DashboardTimer {
        }
    }

    Component {
        id: tasksComponent
        DashboardTasks {
        }
    }

    Component {
        id: mixerComponent
        DashboardAudioMixer {
        }
    }

    Component {
        id: clipboardComponent
        DashboardClipboard {
        }
    }

    Component {
        id: scratchpadComponent
        DashboardScratchpad {
        }
    }
}
