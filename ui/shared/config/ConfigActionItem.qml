import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

RowLayout {
    id: root

    property var configurationItemData: null

    Layout.fillWidth: true
    Layout.preferredHeight: 50
    spacing: 20

    StyledLabel {
        text: root.configurationItemData ? root.configurationItemData.label : ""
        type: "configLabel"
        Layout.fillWidth: true
    }

    BaseButton {
        id: actionButton
        Layout.preferredWidth: 140
        height: 36
        cornerRadius: 8

        onClicked: {
            if (root.configurationItemData.actionId === "verifyGoogleCalendar") {
                GoogleCalendarManager.testConnection()
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: parent.isPressed 
                ? ThemeManager.accentColor 
                : (parent.isHovered ? ThemeManager.surfaceStrongColor : ThemeManager.surfacePrimaryColor)
            border.color: ThemeManager.outlinePrimaryColor
            border.width: 1
        }

        StyledLabel {
            anchors.centerIn: parent
            text: GoogleCalendarManager.isTesting ? "Testing..." : "Test Link"
            type: "button"
            font.pixelSize: 12
            color: actionButton.isPressed ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
        }
    }
}
