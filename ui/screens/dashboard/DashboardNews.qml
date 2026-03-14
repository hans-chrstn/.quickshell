import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared
import qs.ui.screens.dashboard.news

ColumnLayout {
    id: root

    property bool active: false
    
    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

    RowLayout {
        Layout.fillWidth: true
        spacing: 15

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            StyledLabel {
                text: "Intelligence"
                type: "heading"
                font.pixelSize: 28
            }

            StyledLabel {
                text: "Global Wire Feed"
                type: "body"
                opacity: 0.6
            }
        }

        BaseButton {
            width: 44
            height: 44
            cornerRadius: 12
            onClicked: {
                if (NewsManager) {
                    NewsManager.fetchNews(true)
                    SoundManager.playSuccess()
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: {
                    if (parent.isHovered) {
                        return ThemeManager.surfaceStrongColor
                    }
                    return "transparent"
                }
                border.color: ThemeManager.outlineVariantColor
                border.width: 1
            }

            Text {
                anchors.centerIn: parent
                text: "󰑓"
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 20
                opacity: {
                    if (NewsManager && NewsManager.isFetching) {
                        return 1.0
                    }
                    return 0.6
                }
                
                RotationAnimation on rotation {
                    running: {
                        return NewsManager && NewsManager.isFetching
                    }
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }
        }
    }

    NewsSourcePicker {
        id: sourcePicker
        Layout.fillWidth: true
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ListView {
            id: newsList
            anchors.fill: parent
            model: {
                if (!NewsManager) {
                    return null
                }
                return NewsManager.newsStore
            }
            spacing: 12
            clip: true
            interactive: true

            delegate: NewsItemDelegate {
                newsData: model
            }

            StyledLabel {
                anchors.centerIn: parent
                text: "Scanning global frequencies..."
                type: "caption"
                opacity: 0.3
                visible: {
                    if (!NewsManager) return true
                    return NewsManager.newsStore.count === 0 && !NewsManager.isFetching
                }
            }
        }
    }
}
