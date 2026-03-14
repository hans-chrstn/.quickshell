import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.shared
import qs.ui.panels
import qs.ui.shared

SystemPanel {
    id: root

    readonly property bool isLastActive: ViewManager.lastActiveScreenName === root.screen.name

    property bool isDashboardActive: false
    property bool isDashboardExpanded: false
    property int dashboardCurrentPage: 0
    property bool suppressDismiss: false
    
    property bool triggerHovered: false
    property bool contentHovered: false
    readonly property bool isActuallyHovered: triggerHovered || contentHovered

    readonly property var dashboardPages: [
        { "id": "calendar", "title": "Schedule", "icon": "󰥔" },
        { "id": "timer", "title": "Timers & Alarms", "icon": "󰔛" },
        { "id": "tasks", "title": "Tasks & Habits", "icon": "󰄬" },
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
        Qt.callLater(() => {
            root.isDashboardActive = false
        })
    }

    Timer {
        id: collapseTimer
        interval: 300
        onTriggered: {
            if (!root.suppressDismiss && !root.activeFocus) {
                root.isDashboardExpanded = false
            }
        }
    }

    onIsActuallyHoveredChanged: {
        if (isActuallyHovered) {
            collapseTimer.stop()
            root.isDashboardActive = true
            root.isDashboardExpanded = true
        } else {
            collapseTimer.restart()
        }
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
    WlrLayershell.keyboardFocus: root.isDashboardExpanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region {
        Region {
            item: barRect
        }
        Region {
            item: (root.isDashboardActive && root.isLastActive) ? dashboardMaskItem : null
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

        Item {
            id: dashboardTrigger
            anchors.centerIn: parent
            width: parent.width
            height: 200

            HoverHandler {
                onHoveredChanged: {
                    root.triggerHovered = hovered
                }
            }
        }
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
        visible: width > 0
    }

    Item {
        id: dashboardHitbox
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 400
        opacity: 0
        z: 20
        visible: root.isDashboardExpanded

        HoverHandler {
            onHoveredChanged: {
                root.contentHovered = hovered
            }
        }
    }

    Loader {
        id: dashboardLoader
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        z: 5
        active: root.isDashboardActive && root.isLastActive
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
