import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared

Rectangle {
    id: root

    property bool active: false
    property date eventDate: CalendarManager.selectedDate
    property string eventTitle: ""
    property string eventLocation: ""
    property string eventEmail: ""
    property string eventTime: "12:00"
    property bool allDay: false
    property int selectedCategory: 0

    Layout.fillWidth: true
    Layout.preferredHeight: active ? (mainLayout.implicitHeight + 20) : 0
    
    color: ThemeManager.surfaceSubtleColor
    radius: ThemeManager.globalCornerRadius
    border.color: ThemeManager.outlinePrimaryColor
    border.width: 1
    
    opacity: active ? 1.0 : 0.0
    visible: opacity > 0.01
    clip: true

    Behavior on Layout.preferredHeight { 
        NumberAnimation { 
            duration: 400
            easing.type: Easing.OutQuart 
        } 
    }
    
    Behavior on opacity { 
        NumberAnimation { 
            duration: 400
            easing.type: Easing.OutQuart 
        } 
    }

    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 12

        StyledLabel {
            text: "New Event Details"
            type: "title"
            font.pixelSize: 16
            Layout.bottomMargin: 2
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            StyledLabel {
                text: "Title"
                type: "caption"
                opacity: 0.5
                font.pixelSize: 11
            }

            TextField {
                id: titleField
                Layout.fillWidth: true
                placeholderText: "What's happening?"
                text: root.eventTitle
                onTextChanged: root.eventTitle = text
                
                color: "#FFFFFF"
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.3)
                font.family: ThemeManager.fontFamily
                font.pixelSize: 13
                padding: 10
                
                background: Rectangle {
                    radius: 8
                    color: Qt.rgba(0, 0, 0, 0.3)
                    border.color: titleField.activeFocus 
                        ? ThemeManager.accentColor 
                        : Qt.rgba(1, 1, 1, 0.1)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 4
                StyledLabel {
                    text: "Category"
                    type: "caption"
                    opacity: 0.5
                    font.pixelSize: 11
                }
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: CalendarManager.categories
                        delegate: BaseButton {
                            width: 32
                            height: 32
                            cornerRadius: 6
                            tooltip: modelData.label
                            onClicked: root.selectedCategory = index

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: root.selectedCategory === index 
                                    ? modelData.color 
                                    : Qt.rgba(1, 1, 1, 0.05)
                                border.color: root.selectedCategory === index 
                                    ? "transparent" 
                                    : Qt.rgba(1, 1, 1, 0.1)
                                opacity: root.selectedCategory === index ? 1.0 : (parent.isHovered ? 0.3 : 0.1)
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: root.selectedCategory === index 
                                    ? "#000000" 
                                    : modelData.color
                                font.pixelSize: 14
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                spacing: 4
                StyledLabel {
                    text: "All Day"
                    type: "caption"
                    opacity: 0.5
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignHCenter
                }
                Switch {
                    id: allDaySwitch
                    checked: root.allDay
                    onCheckedChanged: root.allDay = checked
                    
                    indicator: Rectangle {
                        implicitWidth: 36
                        implicitHeight: 20
                        radius: 10
                        color: allDaySwitch.checked ? ThemeManager.accentColor : Qt.rgba(1, 1, 1, 0.1)
                        border.color: Qt.rgba(1, 1, 1, 0.1)

                        Rectangle {
                            x: allDaySwitch.checked ? parent.width - width - 2 : 2
                            y: 2
                            width: 16
                            height: 16
                            radius: 8
                            color: allDaySwitch.checked ? "#000000" : "#FFFFFF"
                            Behavior on x { NumberAnimation { duration: 200 } }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: !root.allDay

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledLabel {
                    text: "Time"
                    type: "caption"
                    opacity: 0.5
                    font.pixelSize: 11
                }

                TimePicker {
                    id: timePicker
                    Layout.alignment: Qt.AlignLeft
                    time: root.eventTime
                    onTimeChanged: root.eventTime = time
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                Layout.alignment: Qt.AlignBottom

                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    StyledLabel {
                        text: "Location"
                        type: "caption"
                        opacity: 0.5
                        font.pixelSize: 11
                    }
                    TextField {
                        id: locField
                        Layout.fillWidth: true
                        placeholderText: "Location"
                        text: root.eventLocation
                        onTextChanged: root.eventLocation = text
                        color: "#FFFFFF"
                        font.pixelSize: 12
                        padding: 8
                        background: Rectangle {
                            radius: 6
                            color: Qt.rgba(0, 0, 0, 0.3)
                            border.color: locField.activeFocus ? ThemeManager.accentColor : Qt.rgba(1, 1, 1, 0.1)
                        }
                    }
                }

                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    StyledLabel {
                        text: "Invitees"
                        type: "caption"
                        opacity: 0.5
                        font.pixelSize: 11
                    }
                    TextField {
                        id: emailField
                        Layout.fillWidth: true
                        placeholderText: "Email"
                        text: root.eventEmail
                        onTextChanged: root.eventEmail = text
                        color: "#FFFFFF"
                        font.pixelSize: 12
                        padding: 8
                        background: Rectangle {
                            radius: 6
                            color: Qt.rgba(0, 0, 0, 0.3)
                            border.color: emailField.activeFocus ? ThemeManager.accentColor : Qt.rgba(1, 1, 1, 0.1)
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Layout.topMargin: 4

            BaseButton {
                Layout.fillWidth: true
                height: 36
                cornerRadius: 8
                onClicked: {
                    root.active = false
                    root.eventTitle = ""
                    root.eventLocation = ""
                    root.eventEmail = ""
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                }

                StyledLabel {
                    anchors.centerIn: parent
                    text: "Discard"
                    type: "button"
                    font.pixelSize: 12
                    opacity: 0.7
                }
            }

            BaseButton {
                Layout.fillWidth: true
                height: 36
                cornerRadius: 8
                onClicked: {
                    if (root.eventTitle.trim() === "") return
                    CalendarManager.addEvent({
                        title: root.eventTitle,
                        date: Qt.formatDate(root.eventDate, "yyyy-MM-dd"),
                        time: root.eventTime,
                        allDay: root.allDay,
                        location: root.eventLocation,
                        email: root.eventEmail,
                        category: CalendarManager.categories[root.selectedCategory].id
                    })
                    root.active = false
                    root.eventTitle = ""
                    root.eventLocation = ""
                    root.eventEmail = ""
                    SoundManager.playSuccess()
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: ThemeManager.accentColor
                }

                StyledLabel {
                    anchors.centerIn: parent
                    text: "Create Event"
                    type: "button"
                    font.weight: Font.Bold
                    font.pixelSize: 12
                    color: ThemeManager.contentPrimaryColor
                }
            }
        }
    }
}
