import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

StyledCard {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        StyledLabel {
            text: {
                if (!CalendarManager) {
                    return "Events"
                }
                return "Events for " + Qt.formatDate(CalendarManager.selectedDate, "MMM d")
            }
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
            model: {
                if (!CalendarManager) {
                    return null
                }
                return CalendarManager.filteredModel
            }

            add: Transition {
                NumberAnimation { 
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 400 
                }
                NumberAnimation { 
                    property: "x"
                    from: -30
                    to: 0
                    duration: 400
                    easing.type: Easing.OutQuart 
                }
            }

            remove: Transition {
                NumberAnimation { 
                    property: "opacity"
                    to: 0
                    duration: 300 
                }
                NumberAnimation { 
                    property: "x"
                    to: 30
                    duration: 300
                    easing.type: Easing.InQuart 
                }
            }

            displaced: Transition {
                NumberAnimation { 
                    properties: "y"
                    duration: 400
                    easing.type: Easing.OutCubic 
                }
            }

            delegate: EventDelegate {
                eventData: model
                eventIndex: index
            }

            StyledLabel {
                anchors.centerIn: parent
                text: "No events for this day"
                type: "caption"
                opacity: 0.3
                visible: {
                    return eventList.count === 0
                }
            }
        }
    }
}
