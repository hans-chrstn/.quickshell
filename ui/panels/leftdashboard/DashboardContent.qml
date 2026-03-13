import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared
import "../../screens/dashboard"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true

    readonly property int currentIndex: DashboardManager.currentPage

    Repeater {
        model: DashboardManager.pages.length

        delegate: Loader {
            anchors.fill: parent

            active: root.currentIndex === index 
                || (opacity > 0.01)

            opacity: root.currentIndex === index 
                ? 1.0 
                : 0.0

            visible: opacity > 0.01

            sourceComponent: {
                if (index === 0) return calendarComponent;
                if (index === 1) return mixerComponent;
                if (index === 2) return clipboardComponent;
                if (index === 3) return scratchpadComponent;
                return null;
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: ThemeManager.animationDuration
                    easing.type: Easing.OutQuart
                }
            }

            transform: Translate {
                x: root.currentIndex === index 
                    ? 0 
                    : (root.currentIndex > index ? -30 : 30)

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
