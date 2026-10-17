import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services.settings

ColumnLayout {
    id: root

    spacing: 6

    Text {
        text: "Settings"
        color: Theme.textPrimary
        font.family: Design.fontDisplay
        font.pixelSize: 20
        font.weight: Font.DemiBold
        Layout.leftMargin: 10
        Layout.bottomMargin: 8
    }

    Item {
        id: railContainer
        Layout.fillWidth: true
        Layout.preferredHeight: 38 * SettingsService.categories.length + 6 * (SettingsService.categories.length - 1)

        Column {
            anchors.fill: parent
            spacing: 6

            Repeater {
                model: SettingsService.categories

                delegate: HighlightableSurface {
                    id: category
                    required property int index
                    required property var modelData
                    width: railContainer.width
                    height: 38
                    interactive: false
                    focused: categoryHover.hovered
                    selected: category.index === SettingsService.selectedCategory
                    baseColor: "transparent"
                    cornerRadius: 10

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: category.modelData.title
                        color: category.highlighted ? Theme.textPrimary : Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: 12
                        font.weight: category.index === SettingsService.selectedCategory ? Font.Medium : Font.Normal

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }

                    HoverHandler {
                        id: categoryHover
                    }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: SettingsService.selectedCategory = category.index
                    }
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
