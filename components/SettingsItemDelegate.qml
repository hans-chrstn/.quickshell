import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services

Loader {
    id: root
    width: parent ? parent.width : 0
    
    property var itemData: null

    readonly property bool isFocused: item && item.activeFocus

    onActiveFocusChanged: {
        if (activeFocus && ListView.view) {
            ListView.view.currentIndex = index
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: ThemeManager.contentOnBackgroundColor
        opacity: root.isFocused ? 0.05 : 0
        border.color: ThemeManager.accentColor
        border.width: root.isFocused ? 1 : 0
        z: -1
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    sourceComponent: {
        if (!itemData) return null;
        switch (itemData.type) {
            case "header": return headerComp;
            case "slider": return sliderComp;
            case "color":  return colorComp;
            case "switch": return switchComp;
            case "text":   return textComp;
            default: return null;
        }
    }

    Component {
        id: textComp
        Item {
            width: root.width; height: 44; focus: true
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 16
                Text { text: itemData ? itemData.label : ""; color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 15; opacity: 0.9; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter }
                TextField {
                    id: tInput
                    Layout.preferredWidth: 180; focus: true
                    color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 13; font.family: "Monospace"; Layout.alignment: Qt.AlignVCenter
                    text: itemData ? ThemeManager[itemData.property] : ""
                    activeFocusOnTab: false
                    background: Rectangle { 
                        color: ThemeManager.contentOnBackgroundColor; opacity: 0.05; radius: 8
                        border.color: tInput.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor; border.width: 1
                    }
                    onAccepted: { ThemeManager[itemData.property] = text; ThemeManager.saveConfiguration(); focus = false }
                }
            }
        }
    }

    Component {
        id: headerComp
        Item {
            height: 40; width: root.width
            Text {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.leftMargin: 12
                text: itemData ? itemData.label.toUpperCase() : ""
                color: ThemeManager.accentColor
                font.pixelSize: 11; font.weight: Font.Black; font.letterSpacing: 1.5; opacity: 0.5
            }
        }
    }

    Component {
        id: sliderComp
        Item {
            width: root.width; height: 60; focus: true
            ColumnLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: itemData ? itemData.label : ""; color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 15; opacity: 0.9; Layout.alignment: Qt.AlignVCenter }
                    Item { Layout.fillWidth: true }
                    Text { 
                        text: itemData ? (itemData.step < 1 ? ThemeManager[itemData.property].toFixed(2) : Math.round(ThemeManager[itemData.property])) : ""
                        color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 13; font.weight: Font.Bold; opacity: 0.5; Layout.alignment: Qt.AlignVCenter 
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 34; color: "transparent"
                    Slider {
                        id: sInput
                        anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4
                        focus: true; activeFocusOnTab: false
                        Keys.onLeftPressed: { value -= stepSize; ThemeManager[itemData.property] = value; ThemeManager.saveConfiguration() }
                        Keys.onRightPressed: { value += stepSize; ThemeManager[itemData.property] = value; ThemeManager.saveConfiguration() }
                        from: itemData ? itemData.min : 0; to: itemData ? itemData.max : 100; stepSize: itemData ? (itemData.step || 1) : 1
                        value: itemData ? ThemeManager[itemData.property] : 0
                        onMoved: { ThemeManager[itemData.property] = value }
                        onPressedChanged: { if (!pressed) ThemeManager.saveConfiguration() }
                        background: Rectangle {
                            width: parent.width; height: 6; radius: 3; color: ThemeManager.contentOnBackgroundColor; opacity: 0.1; anchors.centerIn: parent
                            Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 3; color: ThemeManager.accentColor }
                        }
                        handle: Rectangle {
                            x: parent.visualPosition * (parent.availableWidth - width); anchors.verticalCenter: parent.verticalCenter 
                            width: 20; height: 20; radius: 10; color: ThemeManager.contentOnBackgroundColor; border.color: sInput.activeFocus ? "white" : ThemeManager.accentColor; border.width: sInput.activeFocus ? 2 : 1
                            scale: parent.pressed || sInput.activeFocus ? 1.2 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: switchComp
        Item {
            id: switchItem
            width: root.width; height: 44; focus: true
            
            function toggle() {
                ThemeManager[itemData.property] = !ThemeManager[itemData.property]
                ThemeManager.saveConfiguration()
            }

            Keys.onSpacePressed: toggle()
            Keys.onEnterPressed: toggle()
            Keys.onReturnPressed: toggle()

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                Text { text: itemData ? itemData.label : ""; color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 15; opacity: 0.9; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter }
                
                Rectangle {
                    id: swIndicator
                    implicitWidth: 44; implicitHeight: 24; radius: 12
                    Layout.alignment: Qt.AlignVCenter
                    color: ThemeManager[itemData.property] ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                    border.color: switchItem.activeFocus ? "white" : "transparent"; border.width: switchItem.activeFocus ? 2 : 0
                    
                    Rectangle {
                        x: ThemeManager[itemData.property] ? parent.width - width - 2 : 2; y: 2; width: 20; height: 20; radius: 10
                        color: ThemeManager[itemData.property] ? ThemeManager.backgroundPrimaryColor : ThemeManager.contentOnBackgroundColor
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    
                    TapHandler { onTapped: switchItem.toggle() }
                }
            }
        }
    }

    Component {
        id: colorComp
        Item {
            width: root.width; height: 44; focus: true
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 16
                Text { text: itemData ? itemData.label : ""; color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 15; opacity: 0.9; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter }
                TextField {
                    id: cInput
                    Layout.preferredWidth: 100; color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 13; font.family: "Monospace"; focus: true; Layout.alignment: Qt.AlignVCenter
                    text: itemData ? ThemeManager[itemData.property] : ""
                    activeFocusOnTab: false
                    background: Rectangle { 
                        color: ThemeManager.contentOnBackgroundColor; opacity: 0.05; radius: 8; border.color: cInput.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor; border.width: 1
                    }
                    onAccepted: { ThemeManager[itemData.property] = text; ThemeManager.saveConfiguration(); focus = false }
                }
                Rectangle {
                    width: 32; height: 32; radius: 16; Layout.alignment: Qt.AlignVCenter
                    color: itemData ? ThemeManager[itemData.property] : "transparent"
                    border.color: cInput.activeFocus ? "white" : ThemeManager.outlineStrongColor; border.width: 2
                }
            }
        }
    }
}
