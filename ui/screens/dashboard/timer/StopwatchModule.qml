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
        text: "Stopwatch"
        type: "heading"
        font.pixelSize: 24
        Layout.alignment: Qt.AlignLeft
        Layout.bottomMargin: 5
    }

    StyledCard {
        Layout.fillWidth: true
        Layout.preferredHeight: 160

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            StyledLabel { 
                text: {
                    if (!root.chronoEngine) {
                        return "00:00.00"
                    }
                    return root.chronoEngine.formatMs(root.chronoEngine.stopwatchMs)
                }
                font.pixelSize: 42
                font.weight: Font.Black
                font.family: "Monospace" 
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                spacing: 15
                Layout.alignment: Qt.AlignHCenter

                BaseButton { 
                    width: 44
                    height: 44
                    cornerRadius: 22

                    onClicked: {
                        if (root.chronoEngine) {
                            root.chronoEngine.toggleStopwatch()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 22
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                    }

                    Text { 
                        anchors.centerIn: parent
                        text: {
                            if (root.chronoEngine && root.chronoEngine.isStopwatchRunning) {
                                return "󰏤"
                            }
                            return "󰐊"
                        }
                        font.pixelSize: 20
                        color: "white" 
                    } 
                }

                BaseButton { 
                    width: 44
                    height: 44
                    cornerRadius: 22

                    onClicked: {
                        if (root.chronoEngine) {
                            root.chronoEngine.lapStopwatch()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 22
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                    }

                    Text { 
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.pixelSize: 18
                        color: "white" 
                    } 
                }

                BaseButton { 
                    width: 44
                    height: 44
                    cornerRadius: 22

                    onClicked: {
                        if (root.chronoEngine) {
                            root.chronoEngine.resetStopwatch()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 22
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                    }

                    Text { 
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.pixelSize: 18
                        color: "white" 
                    } 
                }
            }
        }
    }

    ListView {
        id: lapList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: {
            return root.chronoEngine ? root.chronoEngine.stopwatchLaps : null
        }
        spacing: 8
        clip: true

        delegate: Rectangle {
            width: ListView.view.width
            height: 40
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.05)

            RowLayout { 
                anchors.fill: parent
                anchors.margins: 10

                StyledLabel { 
                    text: {
                        let total = root.chronoEngine ? root.chronoEngine.stopwatchLaps.count : 0
                        return "Lap " + (total - index)
                    }
                    type: "caption" 
                }

                Item { 
                    Layout.fillWidth: true 
                }

                StyledLabel { 
                    text: "+" + String(model.diff || "")
                    type: "caption"
                    opacity: 0.5 
                }

                StyledLabel { 
                    text: String(model.time || "")
                    font.family: "Monospace" 
                }
            }
        }
    }
}
