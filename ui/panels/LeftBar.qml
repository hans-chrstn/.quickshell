import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui.panels
import qs.ui.shared

SystemPanel {
    id: root

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
    WlrLayershell.keyboardFocus: DashboardManager.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region {
        Region {
            item: barRect
        }
        Region {
            item: (DashboardManager.realActive && ViewManager.lastActiveScreenName === root.screen.name) ? dashboardHitbox : null
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
        id: dashboardHitbox
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 400
        opacity: 0
    }

    Loader {
        id: dashboardLoader
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        z: 5
        active: DashboardManager.realActive && ViewManager.lastActiveScreenName === root.screen.name
        source: "LeftDashboard.qml"
    }
}
