import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    property var chronoEngine: null
    
    spacing: 15
    Layout.fillWidth: true
    Layout.fillHeight: true

    StyledLabel {
        text: "World Clock"
        type: "heading"
        font.pixelSize: 24
        Layout.alignment: Qt.AlignLeft
        Layout.bottomMargin: 5
    }

    ListView {
        id: worldList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: {
            return root.chronoEngine ? root.chronoEngine.worldClockStore : null
        }
        spacing: 10
        clip: true

        delegate: StyledCard { 
            width: ListView.view.width
            height: 70

            RowLayout { 
                anchors.fill: parent
                anchors.margins: 15

                ColumnLayout { 
                    spacing: 2
                    StyledLabel { 
                        text: String(model.city || "")
                        font.pixelSize: 18
                        font.weight: Font.Bold 
                    }
                    StyledLabel { 
                        text: String(model.timezone || "")
                        type: "caption"
                        opacity: 0.5 
                    } 
                }

                Item { 
                    Layout.fillWidth: true 
                }

                StyledLabel { 
                    text: {
                        if (!root.chronoEngine) {
                            return "--:--"
                        }
                        return root.chronoEngine.getZonedTime(model.timezone)
                    }
                    font.pixelSize: 22
                    font.weight: Font.Black
                    font.family: "Monospace" 
                }

                BaseButton { 
                    width: 30
                    height: 30

                    onClicked: {
                        if (root.chronoEngine) {
                            root.chronoEngine.removeWorldClock(index)
                        }
                    }

                    Text { 
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: "red"
                        opacity: 0.5 
                    } 
                }
            }
        }

        header: Item {
            width: ListView.view ? ListView.view.width : 0
            height: 60
            
            RowLayout { 
                anchors.top: parent.top
                width: parent.width
                spacing: 10

                TextField { 
                    id: cityIn
                    Layout.fillWidth: true
                    height: 40
                    placeholderText: "City (e.g. London, Tokyo)"
                    color: ThemeManager.contentOnBackgroundColor
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                    leftPadding: 12
                    
                    background: Rectangle { 
                        radius: 8
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.color: {
                            if (cityIn.activeFocus) {
                                return ThemeManager.accentColor
                            }
                            return Qt.rgba(1, 1, 1, 0.1)
                        }
                        border.width: 1 
                    } 
                }

                BaseButton { 
                    width: 40
                    height: 40
                    cornerRadius: 6

                    onClicked: { 
                        let tzs = {
                            "london": "Europe/London", 
                            "tokyo": "Asia/Tokyo", 
                            "new york": "America/New_York", 
                            "paris": "Europe/Paris", 
                            "berlin": "Europe/Berlin", 
                            "dubai": "Asia/Dubai", 
                            "singapore": "Asia/Singapore", 
                            "sydney": "Australia/Sydney", 
                            "seoul": "Asia/Seoul"
                        }
                        
                        let city = cityIn.text.toLowerCase()
                        if (tzs[city] && root.chronoEngine) { 
                            root.chronoEngine.addWorldClock(
                                cityIn.text, 
                                tzs[city]
                            )
                            cityIn.text = "" 
                        }
                    }

                    Rectangle { 
                        anchors.fill: parent
                        radius: 6
                        color: ThemeManager.accentColor 
                        opacity: 0.8
                    }

                    Text { 
                        anchors.centerIn: parent
                        text: "󰐕"
                        color: ThemeManager.contentPrimaryColor 
                    }
                }
            }
        }
    }
}
