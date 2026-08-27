import QtQuick
import qs.core
import qs.components
import qs.services.launcher
import qs.services.session
import qs.services.settings

Item {
    id: root

    clip: true

    required property string page
    required property string screenName
    property bool expanded: false
    property real expansionProgress: 0
    property date now: new Date()

    Timer {
        interval: 1000
        running: root.visible && root.page === "clock"
        repeat: true
        onTriggered: root.now = new Date()
    }

    Text {
        anchors.centerIn: parent
        visible: root.page === "clock"
        text: Qt.formatDateTime(root.now, "hh:mm")
        color: Design.text
        font.family: Design.fontDisplay
        font.pixelSize: 14 + 10 * root.expansionProgress
        font.weight: root.expanded ? Font.Light : Font.Medium
    }

    CarouselAction {
        anchors.centerIn: parent
        visible: root.page === "power"
        icon: "power"
        label: "Power"
        accent: Design.red
        onActivated: SessionService.open(root.screenName)
    }

    Row {
        anchors.centerIn: parent
        visible: root.page === "utilities"
        spacing: 8

        CarouselAction {
            icon: "apps"
            label: "Launcher"
            accent: Design.blue
            onActivated: LauncherService.open("", root.screenName)
        }
        CarouselAction {
            icon: "settings"
            label: "Settings"
            accent: Design.textMuted
            onActivated: SettingsService.open(root.screenName)
        }
    }
}
