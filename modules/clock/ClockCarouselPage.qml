import QtQuick
import qs.core
import qs.components
import qs.services.audio
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
    readonly property real collapsedImplicitWidth: clockView.collapsedImplicitWidth
    readonly property real collapsedImplicitHeight: clockView.collapsedImplicitHeight
    readonly property real expandedImplicitWidth: page === "clock" ? clockView.expandedImplicitWidth : (page === "power" ? powerAction.implicitWidth : utilitiesRow.implicitWidth)
    readonly property real expandedImplicitHeight: page === "clock" ? clockView.expandedImplicitHeight : (page === "power" ? powerAction.implicitHeight : utilitiesRow.implicitHeight)

    ClockDateTimeView {
        id: clockView
        anchors.fill: parent
        visible: root.page === "clock"
        expansionProgress: root.expansionProgress
    }

    CarouselAction {
        id: powerAction
        anchors.centerIn: parent
        visible: root.page === "power"
        icon: "power"
        label: "Power"
        accent: Theme.danger
        onActivated: SessionService.open(root.screenName)
    }

    Row {
        id: utilitiesRow
        anchors.centerIn: parent
        visible: root.page === "utilities"
        spacing: 8

        CarouselAction {
            icon: "volumeHigh"
            label: "Sound"
            accent: Theme.success
            onActivated: AudioPanelService.open(root.screenName)
        }
        CarouselAction {
            icon: "apps"
            label: "Launcher"
            accent: Theme.accent
            onActivated: LauncherService.open("", root.screenName)
        }
        CarouselAction {
            icon: "settings"
            label: "Settings"
            accent: Theme.textSecondary
            onActivated: SettingsService.open(root.screenName)
        }
    }
}
