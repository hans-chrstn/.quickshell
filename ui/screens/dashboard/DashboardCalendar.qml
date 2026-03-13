import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

ColumnLayout {
    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

    ColumnLayout {
        spacing: 4

        StyledLabel {
            text: DashboardManager.realActive 
                ? Qt.formatDateTime(new Date(), "dddd") 
                : ""
            type: "heading"
            font.pixelSize: 28
        }

        StyledLabel {
            text: DashboardManager.realActive 
                ? Qt.formatDateTime(new Date(), "MMMM d, yyyy") 
                : ""
            type: "body"
            opacity: 0.6
        }
    }

    StyledCard {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            StyledLabel {
                text: "Upcoming Events"
                type: "title"
                font.pixelSize: 16
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: ThemeManager.outlineVariantColor
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    text: "No events scheduled for today"
                    color: ThemeManager.contentOnBackgroundColor
                    opacity: 0.3
                    font.pixelSize: 13
                }
            }
        }
    }
}
