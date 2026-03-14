import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Item {
    id: root

    property var eventData: null
    property int eventIndex: -1
    
    width: parent ? parent.width : 0
    height: 70

    readonly property var category: {
        if (!CalendarManager || !root.eventData) {
            return null
        }
        
        for (let i = 0; i < CalendarManager.categories.length; i++) {
            if (CalendarManager.categories[i].id === root.eventData.category) {
                return CalendarManager.categories[i]
            }
        }
        return CalendarManager.categories[0]
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: ThemeManager.surfaceSubtleColor
        border.color: ThemeManager.outlineVariantColor
        border.width: 1
        opacity: 0.6
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        Rectangle {
            width: 44
            height: 44
            radius: 10
            color: {
                if (!root.category) {
                    return Qt.rgba(1, 1, 1, 0.1)
                }
                return Qt.rgba(
                    root.category.color.r, 
                    root.category.color.g, 
                    root.category.color.b, 
                    0.15
                )
            }
            border.color: {
                if (!root.category) {
                    return Qt.rgba(1, 1, 1, 0.2)
                }
                return Qt.rgba(
                    root.category.color.r, 
                    root.category.color.g, 
                    root.category.color.b, 
                    0.3
                )
            }
            border.width: 1
            
            Text {
                anchors.centerIn: parent
                text: {
                    return root.category ? root.category.icon : ""
                }
                color: {
                    return root.category ? root.category.color : "white"
                }
                font.pixelSize: 22
            }
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            StyledLabel {
                id: titleLabel
                text: {
                    return root.eventData ? String(root.eventData.title || "") : ""
                }
                type: "body"
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true

                HoverHandler {
                    id: titleHover
                    onHoveredChanged: {
                        if (hovered && root.eventData) {
                            TooltipManager.show(
                                titleLabel, 
                                root.eventData.title, 
                                "Calendar Event"
                            )
                        } else {
                            TooltipManager.hide(titleLabel)
                        }
                    }
                }
            }

            RowLayout {
                spacing: 6
                Text {
                    text: "󰊭"
                    color: "#4285F4"
                    font.pixelSize: 13
                    visible: {
                        return root.eventData ? !!root.eventData.isGoogleEvent : false
                    }
                }
                StyledLabel {
                    text: {
                        if (!root.eventData) {
                            return ""
                        }
                        let timeStr = root.eventData.allDay ? "All Day" : (root.eventData.time || "")
                        let locStr = root.eventData.location ? " • " + root.eventData.location : ""
                        return timeStr + locStr
                    }
                    type: "caption"
                    opacity: 0.6
                }
            }
        }

        Item { 
            Layout.fillWidth: true 
        }

        BaseButton {
            width: 36
            height: 36
            cornerRadius: 10
            onClicked: {
                if (root.eventData) {
                    CalendarManager.deleteEvent(
                        root.eventData.id, 
                        !!root.eventData.isGoogleEvent, 
                        root.eventData.title, 
                        root.eventData.date
                    )
                    SoundManager.playCollapse()
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: {
                    return parent.isHovered ? Qt.rgba(1, 0, 0, 0.1) : "transparent"
                }
            }

            Text {
                anchors.centerIn: parent
                text: "󰆴"
                color: {
                    return parent.isHovered ? "#FF4747" : ThemeManager.contentOnBackgroundColor
                }
                font.pixelSize: 18
                opacity: {
                    return parent.isHovered ? 1.0 : 0.4
                }
            }
        }
    }
}
