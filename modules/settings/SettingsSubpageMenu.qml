import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services.settings

SettingPage {
    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Design.space12

        Text {
            text: SettingsService.categories[SettingsService.selectedCategory]?.title ?? ""
            color: Theme.textPrimary
            font.family: Design.fontDisplay
            font.pixelSize: Design.typeDisplay
            font.weight: Font.DemiBold
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Design.space4

            Repeater {
                model: SettingsService.categories[SettingsService.selectedCategory]?.subpages ?? []

                SettingNavigationTile {
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    title: modelData.title
                    description: modelData.desc
                    onActivated: SettingsService.openPage(modelData.id)
                    opacity: 0
                    transform: Translate {
                        id: rowOffset
                        x: Design.reducedMotion ? 0 : 12
                    }

                    SequentialAnimation on opacity {
                        running: true
                        PauseAnimation {
                            duration: index * Design.settingsRowStagger
                        }
                        NumberAnimation {
                            to: 1
                            duration: Design.settingsRowEntrance
                            easing.type: Easing.OutCubic
                        }
                    }

                    SequentialAnimation {
                        running: !Design.reducedMotion
                        PauseAnimation {
                            duration: index * Design.settingsRowStagger
                        }
                        SpatialSpring {
                            target: rowOffset
                            property: "x"
                            to: 0
                            phase: "enter"
                        }
                    }
                }
            }
        }
    }
}
