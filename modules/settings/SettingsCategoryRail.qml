import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.settings

ColumnLayout {
    id: root

    spacing: 6

    Text {
        text: "Settings"
        color: Design.text
        font.family: Design.fontDisplay
        font.pixelSize: 20
        font.weight: Font.DemiBold
        Layout.leftMargin: 10
        Layout.bottomMargin: 8
    }

    Item {
        id: railContainer
        Layout.fillWidth: true
        Layout.preferredHeight: 38 * SettingsService.categories.length
            + 6 * (SettingsService.categories.length - 1)

        Rectangle {
            width: parent.width
            height: 38
            y: SettingsService.selectedCategory * 44
            radius: 10
            color: Design.surfaceRaised
            border.width: 1
            border.color: Design.glassHighlight

            Behavior on y {
                NumberAnimation {
                    duration: Design.resizeDuration * 0.5
                    easing.type: Easing.OutCubic
                }
            }
        }

        Column {
            anchors.fill: parent
            spacing: 6

            Repeater {
                model: SettingsService.categories

                delegate: Item {
                    id: category
                    required property int index
                    required property var modelData
                    width: railContainer.width
                    height: 38

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: category.modelData.title
                        color: category.index === SettingsService.selectedCategory
                            || categoryHover.hovered ? Design.text : Design.textMuted
                        font.family: Design.fontText
                        font.pixelSize: 12
                        font.weight: category.index === SettingsService.selectedCategory
                            ? Font.Medium : Font.Normal

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    HoverHandler { id: categoryHover }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: SettingsService.selectedCategory = category.index
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
