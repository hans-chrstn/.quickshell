import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.settings

Item {
    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 12

        Text {
            text: SettingsService.categories[SettingsService.selectedCategory]?.title ?? ""
            color: Design.text
            font.family: Design.fontDisplay
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: SettingsService.categories[SettingsService.selectedCategory]?.subpages ?? []

                SettingNavigationTile {
                    required property var modelData
                    Layout.fillWidth: true
                    title: modelData.title
                    description: modelData.desc
                    onActivated: SettingsService.openPage(modelData.id)
                }
            }
        }
    }
}
