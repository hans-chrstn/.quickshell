import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Item {
    id: root

    height: 40
    Layout.fillWidth: true

    readonly property int targetIndex: {
        if (!NewsManager) {
            return 0
        }
        return NewsManager.activeSource === "wire" ? 0 : 1
    }

    SelectionPill {
        id: sourceIndicator
        width: {
            return (parent.width - 8) / 2
        }
        height: parent.height
        radius: 10
        x: {
            return root.targetIndex * (width + 8)
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8
        z: 1

        Repeater {
            model: [
                { "id": "wire", "label": "The Guardian", "icon": "󰋙" },
                { "id": "global", "label": "Global Voices", "icon": "󰋋" }
            ]

            delegate: BaseButton {
                Layout.fillWidth: true
                height: 40
                cornerRadius: 10

                onClicked: {
                    if (NewsManager) {
                        NewsManager.activeSource = modelData.id
                        SoundManager.playClick()
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: modelData.icon
                        font.pixelSize: 16
                        color: {
                            if (NewsManager && NewsManager.activeSource === modelData.id) {
                                return ThemeManager.contentPrimaryColor
                            }
                            return ThemeManager.contentOnBackgroundColor
                        }
                        opacity: {
                            if (NewsManager && NewsManager.activeSource === modelData.id) {
                                return 1.0
                            }
                            return 0.5
                        }
                    }

                    StyledLabel {
                        text: modelData.label
                        type: "label"
                        font.pixelSize: 11
                        color: {
                            if (NewsManager && NewsManager.activeSource === modelData.id) {
                                return ThemeManager.contentPrimaryColor
                            }
                            return ThemeManager.contentOnBackgroundColor
                        }
                    }
                }
            }
        }
    }
}
