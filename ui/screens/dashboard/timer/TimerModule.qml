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
        text: "Timer"
        type: "heading"
        font.pixelSize: 24
        Layout.alignment: Qt.AlignLeft
        Layout.bottomMargin: 5
    }

    StyledCard {
        Layout.fillWidth: true
        Layout.preferredHeight: 240
        
        ProgressRing {
            anchors.centerIn: parent
            width: 200
            height: 200
            strokeWidth: 8
            value: {
                if (root.chronoEngine && root.chronoEngine.lastStartedSeconds > 0) {
                    return 1.0 - (root.chronoEngine.countdownSeconds / root.chronoEngine.lastStartedSeconds)
                }
                return 0
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            StyledLabel {
                text: {
                    if (!root.chronoEngine) {
                        return "00:00"
                    }
                    return root.chronoEngine.getFormattedTime(root.chronoEngine.countdownSeconds)
                }
                font.pixelSize: 48
                font.weight: Font.Black
                font.family: "Monospace"
                color: {
                    if (root.chronoEngine && root.chronoEngine.isCounting) {
                        return ThemeManager.accentColor
                    }
                    return ThemeManager.contentOnBackgroundColor
                }
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                spacing: 20
                Layout.alignment: Qt.AlignHCenter

                BaseButton { 
                    width: 44
                    height: 44
                    cornerRadius: 22

                    onClicked: {
                        if (root.chronoEngine) {
                            root.chronoEngine.toggleExecution()
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
                            if (root.chronoEngine && root.chronoEngine.isCounting) {
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
                            root.chronoEngine.revertToLastStart()
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
                        text: "󰕌"
                        font.pixelSize: 18
                        color: "white" 
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Repeater {
            model: [
                { label: "+1m", seconds: 60 }, 
                { label: "+5m", seconds: 300 }, 
                { label: "+10m", seconds: 600 }
            ]

            delegate: BaseButton {
                Layout.fillWidth: true
                height: 40
                cornerRadius: 10

                onClicked: {
                    if (root.chronoEngine) {
                        root.chronoEngine.modifyCountdown(modelData.seconds)
                    }
                }

                Rectangle { 
                    anchors.fill: parent
                    radius: 10
                    color: ThemeManager.surfaceSubtleColor
                    border.color: ThemeManager.outlineVariantColor
                    border.width: 1 
                }

                StyledLabel { 
                    anchors.centerIn: parent
                    text: modelData.label
                    type: "body" 
                }
            }
        }
    }

    StyledLabel {
        text: "Presets"
        type: "caption"
        opacity: 0.5
        Layout.topMargin: 10
    }

    ListView {
        id: presetList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: {
            if (!root.chronoEngine) {
                return null
            }
            return root.chronoEngine.presetStore
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
                    text: String(model.label || "")
                    type: "body"
                    Layout.fillWidth: true
                }

                StyledLabel {
                    text: {
                        if (!root.chronoEngine) {
                            return ""
                        }
                        return root.chronoEngine.getFormattedTime(model.seconds)
                    }
                    type: "caption"
                    opacity: 0.6
                }

                BaseButton {
                    width: 24
                    height: 24

                    onClicked: {
                        if (root.chronoEngine) {
                            root.chronoEngine.initiateCountdown(model.seconds)
                        }
                    }

                    Text { 
                        anchors.centerIn: parent
                        text: "󰐊"
                        color: ThemeManager.accentColor
                        font.pixelSize: 14 
                    }
                }

                BaseButton {
                    width: 24
                    height: 24

                    onClicked: {
                        if (root.chronoEngine) {
                            root.chronoEngine.removePreset(index)
                        }
                    }

                    Text { 
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: "red"
                        opacity: 0.5
                        font.pixelSize: 14 
                    }
                }
            }
        }

        header: Item {
            width: ListView.view ? ListView.view.width : 0
            height: 56
            
            RowLayout {
                anchors.top: parent.top
                width: parent.width
                spacing: 8
                
                TextField {
                    id: presetNameIn
                    Layout.fillWidth: true
                    height: 40
                    placeholderText: "New Preset Name"
                    color: ThemeManager.contentOnBackgroundColor
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                    leftPadding: 12
                    
                    background: Rectangle { 
                        radius: 8
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.color: {
                            if (presetNameIn.activeFocus) {
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
                    cornerRadius: 8

                    onClicked: {
                        if (root.chronoEngine && presetNameIn.text !== "" && root.chronoEngine.countdownSeconds > 0) {
                            root.chronoEngine.addPreset(
                                presetNameIn.text, 
                                root.chronoEngine.countdownSeconds
                            )
                            presetNameIn.text = ""
                        }
                    }

                    Rectangle { 
                        anchors.fill: parent
                        radius: 8
                        color: ThemeManager.accentColor 
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
