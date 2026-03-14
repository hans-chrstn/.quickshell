import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

RowLayout {
    id: root

    property alias isEditorActive: eventAddBtn.isEditorActive
    
    signal syncTriggered()
    signal addTriggered()

    Layout.fillWidth: true
    spacing: 15

    ColumnLayout {
        spacing: 4
        Layout.fillWidth: true

        StyledLabel {
            text: "Calendar"
            type: "heading"
            font.pixelSize: 28
        }

        StyledLabel {
            text: Qt.formatDateTime(new Date(), "MMMM d, yyyy")
            type: "body"
            opacity: 0.6
        }
    }

    RowLayout {
        spacing: 8

        BaseButton {
            width: 44
            height: 44
            cornerRadius: 12
            visible: {
                return !!ThemeManager.googleCalendarEnabled
            }
            onClicked: {
                root.syncTriggered()
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: {
                    return parent.isHovered ? ThemeManager.surfaceStrongColor : "transparent"
                }
                border.color: ThemeManager.outlineVariantColor
                border.width: 1
            }

            Text {
                anchors.centerIn: parent
                text: "󰑓"
                color: {
                    if (GoogleCalendarManager && GoogleCalendarManager.isTesting) {
                        return ThemeManager.accentColor
                    }
                    return ThemeManager.contentOnBackgroundColor
                }
                font.pixelSize: 22
                opacity: {
                    return parent.isHovered ? 1.0 : 0.6
                }
                
                RotationAnimation on rotation {
                    running: {
                        return GoogleCalendarManager && GoogleCalendarManager.isTesting
                    }
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }
        }

        BaseButton {
            id: eventAddBtn
            property bool isEditorActive: false
            
            width: 44
            height: 44
            cornerRadius: 12
            onClicked: {
                root.addTriggered()
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: {
                    return parent.isHovered ? ThemeManager.surfaceStrongColor : "transparent"
                }
                border.color: ThemeManager.outlineVariantColor
                border.width: 1
            }

            Text {
                anchors.centerIn: parent
                text: "󰐕"
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 24
                opacity: {
                    return parent.isHovered ? 1.0 : 0.6
                }
            }
        }
    }
}
