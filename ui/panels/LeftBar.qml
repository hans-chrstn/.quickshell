import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.shared
import qs.ui.panels
import qs.ui.shared

SystemPanel {
    id: root

    readonly property bool isLastActive: {
        return ViewManager.lastActiveScreenName === root.screen.name
    }

    property bool isDashboardActive: false
    property bool isDashboardExpanded: ViewManager.leftDashboardOpen
    property int dashboardCurrentPage: 0
    property bool suppressDismiss: false
    
    onIsDashboardExpandedChanged: {
        if (isDashboardExpanded) {
            root.isDashboardActive = true
        }
    }

    readonly property var dashboardPages: [
        { "id": "news", "title": "Intelligence", "icon": "󰋙" },
        { "id": "weather", "title": "Weather Hub", "icon": "󰖐" },
        { "id": "calendar", "title": "Schedule", "icon": "󰥔" },
        { "id": "tasks", "title": "Tasks & Habits", "icon": "󰄬" },
        { "id": "timer", "title": "Timers & Alarms", "icon": "󰔛" },
        { "id": "mixer", "title": "Audio Mixer", "icon": "󰕾" },
        { "id": "clipboard", "title": "Clipboard", "icon": "󰅍" },
        { "id": "notes", "title": "Scratchpad", "icon": "󰠮" }
    ]

    property bool suppressChronoOSD: false

    ChronoEngine {
        id: chronoEngine
        
        onAlertTriggered: (label) => {
            root.suppressChronoOSD = false
            OSDManager.show("message", "Alarm: " + label, ThemeManager.iconClock)
            SoundManager.playSuccess()
        }
        
        onCountdownFinished: {
            root.suppressChronoOSD = false
            OSDManager.show("message", "Timer Finished", ThemeManager.iconClock)
            SoundManager.playSuccess()
            OSDManager.hide("chrono")
        }

        onCountdownSecondsChanged: {
            if (isCounting && !root.suppressChronoOSD) {
                OSDManager.show("chrono", chronoEngine.getFormattedTime(countdownSeconds))
            }
        }

        onIsCountingChanged: {
            if (isCounting) {
                root.suppressChronoOSD = false
            } else if (countdownSeconds > 0) {
                OSDManager.hide("chrono")
            }
        }

        onActiveModeChanged: {
            root.suppressChronoOSD = false
            if (!isCounting) {
                OSDManager.hide("chrono")
            }
        }
    }

    Connections {
        target: OSDManager
        function onManuallyHidden(type) {
            if (type === "chrono" && chronoEngine.isCounting) {
                root.suppressChronoOSD = true
            }
        }
    }

    function finalizeClose() {
        root.isDashboardActive = false
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered && root.screen) {
                ViewManager.trackScreen(root.screen.name)
            }
        }
    }

    anchors.left: true
    anchors.top: true
    anchors.bottom: true

    implicitWidth: 450
    color: "transparent"

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: ThemeManager.globalThickness
    WlrLayershell.layer: WlrLayer.Bottom

    focusable: true
    WlrLayershell.keyboardFocus: {
        return root.isDashboardExpanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    }

    mask: Region {
        Region {
            item: barRect
        }
        Region {
            item: {
                return (root.isDashboardActive && root.isLastActive) ? dashboardMaskItem : null
            }
        }
    }

    Rectangle {
        id: barRect
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: ThemeManager.globalThickness
        color: ThemeManager.backgroundColor
        z: 10
    }

    Item {
        id: dashboardMaskItem
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: {
            if (dashboardLoader.item) {
                return Math.max(0, dashboardLoader.item.x + dashboardLoader.item.width)
            }
            return 0
        }
        visible: {
            return width > 0
        }
    }

    Loader {
        id: dashboardLoader
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        z: 5
        active: {
            return root.isDashboardActive && root.isLastActive
        }
        source: "LeftDashboard.qml"
        
        Binding {
            target: dashboardLoader.item
            property: "active"
            value: root.isDashboardExpanded
        }

        Binding {
            target: dashboardLoader.item
            property: "currentPage"
            value: root.dashboardCurrentPage
        }

        Binding {
            target: dashboardLoader.item
            property: "chronoEngine"
            value: chronoEngine
        }

        Connections {
            target: dashboardLoader.item
            ignoreUnknownSignals: true
            
            function onCurrentPageChanged() {
                if (dashboardLoader.item) {
                    root.dashboardCurrentPage = dashboardLoader.item.currentPage
                }
            }
            
            function onSuppressDismissChanged() {
                if (dashboardLoader.item) {
                    root.suppressDismiss = dashboardLoader.item.suppressDismiss
                }
            }
        }

        onLoaded: {
            if (item) {
                item.pages = root.dashboardPages
            }
        }
    }
}
