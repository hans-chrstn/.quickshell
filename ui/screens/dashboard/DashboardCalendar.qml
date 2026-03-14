import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared
import "./calendar"

ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

    property bool active: false

    onActiveChanged: {
        if (!active) {
            eventEditor.active = false
        }
    }

    RowLayout {
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
                tooltip: "Sync Google Calendar"
                visible: ThemeManager.googleCalendarEnabled
                onClicked: {
                    CalendarManager.triggerSync()
                    SoundManager.playSuccess()
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: parent.isHovered 
                        ? ThemeManager.surfaceStrongColor 
                        : "transparent"
                    border.color: ThemeManager.outlineVariantColor
                    border.width: 1
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰑓"
                    color: GoogleCalendarManager.isTesting ? ThemeManager.accentColor : ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 22
                    opacity: parent.isHovered ? 1.0 : 0.6
                    
                    RotationAnimation on rotation {
                        running: GoogleCalendarManager.isTesting
                        from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                    }
                }
            }

            BaseButton {
                width: 44
                height: 44
                cornerRadius: 12
                tooltip: "Add Event"
                onClicked: eventEditor.active = !eventEditor.active

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: parent.isHovered 
                        ? ThemeManager.surfaceStrongColor 
                        : "transparent"
                    border.color: ThemeManager.outlineVariantColor
                    border.width: 1
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰐕"
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 24
                    opacity: parent.isHovered ? 1.0 : 0.6
                }
            }
        }
    }

    CalendarGrid {
        id: calendarGrid
        Layout.fillWidth: true
    }

    EventEditor {
        id: eventEditor
        active: false
        eventDate: CalendarManager.selectedDate
    }

    Item {
        id: eventCardContainer
        Layout.fillWidth: true
        Layout.fillHeight: true

        StyledCard {
            id: eventCard
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                StyledLabel {
                    text: "Events for " + Qt.formatDate(CalendarManager.selectedDate, "MMM d")
                    type: "title"
                    font.pixelSize: 16
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: ThemeManager.outlineVariantColor
                    opacity: 0.5
                }

                ListView {
                    id: eventList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12
                    clip: true
                    model: CalendarManager.filteredModel

                    add: Transition {
                        NumberAnimation { 
                            property: "opacity"; 
                            from: 0; 
                            to: 1; 
                            duration: 400 
                        }
                        NumberAnimation { 
                            property: "x"; 
                            from: -30; 
                            to: 0; 
                            duration: 400; 
                            easing.type: Easing.OutQuart 
                        }
                    }

                    remove: Transition {
                        NumberAnimation { 
                            property: "opacity"; 
                            to: 0; 
                            duration: 300 
                        }
                        NumberAnimation { 
                            property: "x"; 
                            to: 30; 
                            duration: 300; 
                            easing.type: Easing.InQuart 
                        }
                    }

                    displaced: Transition {
                        NumberAnimation { 
                            properties: "y"; 
                            duration: 400; 
                            easing.type: Easing.OutCubic 
                        }
                    }

                    delegate: Item {
                        id: delegateRoot
                        width: eventList.width
                        height: 70

                        readonly property var cat: {
                            for (let i = 0; i < CalendarManager.categories.length; i++) {
                                if (CalendarManager.categories[i].id === model.category) return CalendarManager.categories[i]
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
                                color: Qt.rgba(delegateRoot.cat.color.r, delegateRoot.cat.color.g, delegateRoot.cat.color.b, 0.15)
                                border.color: Qt.rgba(delegateRoot.cat.color.r, delegateRoot.cat.color.g, delegateRoot.cat.color.b, 0.3)
                                border.width: 1
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: delegateRoot.cat.icon
                                    color: delegateRoot.cat.color
                                    font.pixelSize: 22
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true

                                StyledLabel {
                                    id: titleLabel
                                    text: model.title
                                    type: "body"
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true

                                    HoverHandler {
                                        id: titleHover
                                        onHoveredChanged: {
                                            if (hovered) {
                                                TooltipManager.show(titleLabel, model.title, "Calendar Event")
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
                                        visible: model.isGoogleEvent === true
                                    }
                                    StyledLabel {
                                        text: (model.allDay ? "All Day" : model.time) 
                                            + (model.location ? " • " + model.location : "")
                                        type: "caption"
                                        opacity: 0.6
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            BaseButton {
                                width: 36
                                height: 36
                                cornerRadius: 10
                                tooltip: "Delete"
                                onClicked: {
                                    CalendarManager.deleteEvent(model.id, model.isGoogleEvent === true, model.title, model.date)
                                    SoundManager.playCollapse()
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    color: parent.isHovered ? Qt.rgba(1, 0, 0, 0.1) : "transparent"
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆴"
                                    color: parent.isHovered ? "#FF4747" : ThemeManager.contentOnBackgroundColor
                                    font.pixelSize: 18
                                    opacity: parent.isHovered ? 1.0 : 0.4
                                }
                            }
                        }
                    }

                    StyledLabel {
                        anchors.centerIn: parent
                        text: "No events for this day"
                        type: "caption"
                        opacity: 0.3
                        visible: eventList.count === 0
                    }
                }
            }
        }
    }
}
