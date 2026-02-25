import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core

Loader {
    id: root
    
    width: parent ? parent.width : 0
    
    property var configurationItemData: null

    readonly property bool isCurrentlyFocused: item && item.activeFocus

    onActiveFocusChanged: {
        if (activeFocus && ListView.view) {
            ListView.view.currentIndex = index
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: ThemeManager.contentOnBackgroundColor
        opacity: root.isCurrentlyFocused ? 0.05 : 0
        border.color: ThemeManager.accentColor
        border.width: root.isCurrentlyFocused ? 1 : 0
        z: -1
        Behavior on opacity { 
            NumberAnimation { 
                duration: 200 
            } 
        }
    }

    sourceComponent: {
        if (!configurationItemData) return null;
        switch (configurationItemData.type) {
            case "header": return headerComponent;
            case "slider": return sliderComponent;
            case "color":  return colorPickerComponent;
            case "switch": return switchToggleComponent;
            case "text":   return textInputComponent;
            default: return null;
        }
    }

    Component {
        id: textInputComponent
        Item {
            width: root.width
            height: 44
            focus: true
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 16
                
                Text { 
                    text: configurationItemData ? configurationItemData.label : ""
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 15
                    opacity: 0.9
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter 
                }
                
                TextField {
                    id: textInput
                    Layout.preferredWidth: 180
                    focus: true
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 13
                    font.family: "Monospace"
                    Layout.alignment: Qt.AlignVCenter
                    text: configurationItemData ? ThemeManager[configurationItemData.property] : ""
                    activeFocusOnTab: false
                    
                    background: Rectangle { 
                        color: ThemeManager.contentOnBackgroundColor
                        opacity: 0.05
                        radius: 8
                        border.color: textInput.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                        border.width: 1
                    }
                    
                    onAccepted: { 
                        ThemeManager[configurationItemData.property] = text
                        ThemeManager.saveConfiguration()
                        focus = false 
                    }
                }
            }
        }
    }

    Component {
        id: headerComponent
        Item {
            height: 40
            width: root.width
            
            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                anchors.leftMargin: 12
                text: configurationItemData ? configurationItemData.label.toUpperCase() : ""
                color: ThemeManager.accentColor
                font.pixelSize: 11
                font.weight: Font.Black
                font.letterSpacing: 1.5
                opacity: 0.5
            }
        }
    }

    Component {
        id: sliderComponent
        Item {
            width: root.width
            height: 60
            focus: true
            
            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 4
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text { 
                        text: configurationItemData ? configurationItemData.label : ""
                        color: ThemeManager.contentOnBackgroundColor
                        font.pixelSize: 15
                        opacity: 0.9
                        Layout.alignment: Qt.AlignVCenter 
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text { 
                        text: configurationItemData ? (configurationItemData.step < 1 ? ThemeManager[configurationItemData.property].toFixed(2) : Math.round(ThemeManager[configurationItemData.property])) : ""
                        color: ThemeManager.contentOnBackgroundColor
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        opacity: 0.5
                        Layout.alignment: Qt.AlignVCenter 
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    color: "transparent"
                    
                    Slider {
                        id: sliderInput
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        focus: true
                        activeFocusOnTab: false
                        
                        Keys.onLeftPressed: { 
                            value -= stepSize
                            ThemeManager[configurationItemData.property] = value
                            ThemeManager.saveConfiguration() 
                        }
                        Keys.onRightPressed: { 
                            value += stepSize
                            ThemeManager[configurationItemData.property] = value
                            ThemeManager.saveConfiguration() 
                        }
                        
                        from: configurationItemData ? configurationItemData.min : 0
                        to: configurationItemData ? configurationItemData.max : 100
                        stepSize: configurationItemData ? (configurationItemData.step || 1) : 1
                        value: configurationItemData ? ThemeManager[configurationItemData.property] : 0
                        
                        onMoved: { 
                            ThemeManager[configurationItemData.property] = value 
                        }
                        
                        onPressedChanged: { 
                            if (!pressed) {
                                ThemeManager.saveConfiguration() 
                            }
                        }
                        
                        background: Rectangle {
                            width: parent.width
                            height: 6
                            radius: 3
                            color: ThemeManager.contentOnBackgroundColor
                            opacity: 0.1
                            anchors.centerIn: parent
                            
                            Rectangle { 
                                width: parent.parent.visualPosition * parent.width
                                height: parent.height
                                radius: 3
                                color: ThemeManager.accentColor 
                            }
                        }
                        
                        handle: Rectangle {
                            x: parent.visualPosition * (parent.availableWidth - width)
                            anchors.verticalCenter: parent.verticalCenter 
                            width: 20
                            height: 20
                            radius: 10
                            color: ThemeManager.contentOnBackgroundColor
                            border.color: sliderInput.activeFocus ? "white" : ThemeManager.accentColor
                            border.width: sliderInput.activeFocus ? 2 : 1
                            scale: parent.pressed || sliderInput.activeFocus ? 1.2 : 1.0
                            Behavior on scale { 
                                NumberAnimation { 
                                    duration: 150 
                                } 
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: switchToggleComponent
        Item {
            id: switchWrapper
            width: root.width
            height: 44
            focus: true
            
            function performToggle() {
                ThemeManager[configurationItemData.property] = !ThemeManager[configurationItemData.property]
                ThemeManager.saveConfiguration()
            }

            Keys.onSpacePressed: performToggle()
            Keys.onEnterPressed: performToggle()
            Keys.onReturnPressed: performToggle()

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                
                Text { 
                    text: configurationItemData ? configurationItemData.label : ""
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 15
                    opacity: 0.9
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter 
                }
                
                Rectangle {
                    id: switchIndicator
                    implicitWidth: 44
                    implicitHeight: 24
                    radius: 12
                    Layout.alignment: Qt.AlignVCenter
                    color: ThemeManager[configurationItemData.property] ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                    border.color: switchWrapper.activeFocus ? "white" : "transparent"
                    border.width: switchWrapper.activeFocus ? 2 : 0
                    
                    Rectangle {
                        x: ThemeManager[configurationItemData.property] ? parent.width - width - 2 : 2
                        y: 2
                        width: 20
                        height: 20
                        radius: 10
                        color: ThemeManager[configurationItemData.property] ? ThemeManager.backgroundPrimaryColor : ThemeManager.contentOnBackgroundColor
                        Behavior on x { 
                            NumberAnimation { 
                                duration: 200
                                easing.type: Easing.OutQuart 
                            } 
                        }
                        Behavior on color { 
                            ColorAnimation { 
                                duration: 200 
                            } 
                        }
                    }
                    
                    TapHandler { 
                        onTapped: switchWrapper.performToggle() 
                    }
                }
            }
        }
    }

    Component {
        id: colorPickerComponent
        Item {
            width: root.width
            height: 44
            focus: true
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 16
                
                Text { 
                    text: configurationItemData ? configurationItemData.label : ""
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 15
                    opacity: 0.9
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter 
                }
                
                TextField {
                    id: colorInput
                    Layout.preferredWidth: 100
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 13
                    font.family: "Monospace"
                    focus: true
                    Layout.alignment: Qt.AlignVCenter
                    text: configurationItemData ? ThemeManager[configurationItemData.property] : ""
                    activeFocusOnTab: false
                    
                    background: Rectangle { 
                        color: ThemeManager.contentOnBackgroundColor
                        opacity: 0.05
                        radius: 8
                        border.color: colorInput.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                        border.width: 1
                    }
                    
                    onAccepted: { 
                        ThemeManager[configurationItemData.property] = text
                        ThemeManager.saveConfiguration()
                        focus = false 
                    }
                }
                
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    Layout.alignment: Qt.AlignVCenter
                    color: configurationItemData ? ThemeManager[configurationItemData.property] : "transparent"
                    border.color: colorInput.activeFocus ? "white" : ThemeManager.outlineStrongColor
                    border.width: 2
                }
            }
        }
    }
}
