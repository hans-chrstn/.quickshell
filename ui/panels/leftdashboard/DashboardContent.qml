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

    readonly property int currentIndex: root.currentPage

    Repeater {
        model: root.pages ? root.pages.length : 0

        delegate: Loader {
            anchors.fill: parent

            active: contentRoot.currentIndex === index 
                || (opacity > 0.01)

            opacity: contentRoot.currentIndex === index 
                ? 1.0 
                : 0.0

            visible: opacity > 0.01

            sourceComponent: {
                if (index === 0) return calendarComponent;
                if (index === 1) return timerComponent;
                if (index === 2) return mixerComponent;
                if (index === 3) return clipboardComponent;
                if (index === 4) return scratchpadComponent;
                return null;
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
                when: index === 1
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: ThemeManager.animationDuration
                    easing.type: Easing.OutQuart
                }
            }

            transform: Translate {
                x: contentRoot.currentIndex === index 
                    ? 0 
                    : (contentRoot.currentIndex > index ? -30 : 30)

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
        DashboardCalendar {}
    }

    Component {
        id: timerComponent
        DashboardTimer {}
    }

    Component {
        id: mixerComponent
        DashboardAudioMixer {}
    }

    Component {
        id: clipboardComponent
        DashboardClipboard {}
    }

    Component {
        id: scratchpadComponent
        DashboardScratchpad {}
    }
}
