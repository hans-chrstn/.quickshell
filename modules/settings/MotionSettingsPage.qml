import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components.scrolling
import qs.core
import qs.services.settings

SettingPage {
    Flickable {
        id: settingsScroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: settingsColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        SmoothScrollBehavior {
            target: settingsScroll
        }
        ScrollEdgeFeedback {
            target: settingsScroll
        }
        ScrollBar.vertical: MinimalScrollBar {}

        ColumnLayout {
            id: settingsColumn
            width: settingsScroll.width - Design.space8
            spacing: Design.space8

            SettingsHeader {
                title: "Motion"
            }

            SettingSlider {
                Layout.fillWidth: true
                title: "Entrance fade"
                description: "Shared shell surfaces"
                from: 150
                to: 600
                stepSize: 10
                value: SettingsService.topIslandEnterFadeDuration
                onValueEdited: value => SettingsService.setSetting("topIslandEnterFadeDuration", value)
            }
            SettingSlider {
                Layout.fillWidth: true
                title: "Exit fade"
                description: "Shared shell surfaces"
                from: 180
                to: 700
                stepSize: 10
                value: SettingsService.topIslandExitFadeDuration
                onValueEdited: value => SettingsService.setSetting("topIslandExitFadeDuration", value)
            }
            SettingSlider {
                Layout.fillWidth: true
                title: "Content reveal"
                description: "Page and route changes"
                from: 100
                to: 400
                stepSize: 10
                value: SettingsService.topIslandContentFadeDuration
                onValueEdited: value => SettingsService.setSetting("topIslandContentFadeDuration", value)
            }

            SettingButton {
                label: "Reset Motion"
                Layout.alignment: Qt.AlignRight
                onClicked: SettingsService.resetMotion()
            }
        }
    }
}
