import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.components

PanelWindow {
    id: root
    
    visible: false
    color: "transparent"
    
    anchors {
        left: true; right: true; top: true; bottom: true
    }
    
    exclusionMode: ExclusionMode.Ignore
    focusable: visible

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.visible ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    function getModel() {
        if (categoryList.currentIndex >= 0 && categoryList.currentIndex < FrameConfig.settingsStructure.length) {
            return FrameConfig.settingsStructure[categoryList.currentIndex].items
        }
        return []
    }

    ClippingRectangle {
        id: windowFrame
        width: 850; height: 550
        anchors.centerIn: parent
        radius: 28
        color: FrameConfig.color
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        opacity: root.visible ? 1.0 : 0
        scale: root.visible ? 1.0 : 0.95
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        
        MouseArea {
            anchors.fill: parent
            z: -1
            onPressed: (mouse) => mouse.accepted = true
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 240
                Layout.fillHeight: true
                color: Qt.rgba(1, 1, 1, 0.02)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: "SETTINGS"
                        color: "white"
                        font.pixelSize: 12; font.weight: Font.Black; font.letterSpacing: 2
                        opacity: 0.4
                        Layout.margins: 16
                    }

                    ListView {
                        id: categoryList
                        Layout.fillWidth: true; Layout.fillHeight: true
                        model: FrameConfig.settingsStructure
                        clip: true
                        currentIndex: 0
                        spacing: 4
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
                        footer: Item { height: 20 }
                        
                        Behavior on contentY { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                        
                        delegate: Rectangle {
                            width: categoryList.width
                            height: 48; radius: 12
                            color: ListView.isCurrentItem ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 16; spacing: 12
                                
                                Item {
                                    width: 28; height: parent.height
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        color: "white"
                                        font.pixelSize: 20
                                        opacity: ListView.isCurrentItem ? 1.0 : 0.4
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                    }
                                }
                                
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.category
                                    color: "white"
                                    font.pixelSize: 14; font.weight: ListView.isCurrentItem ? Font.DemiBold : Font.Normal
                                    opacity: ListView.isCurrentItem ? 1.0 : 0.6
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                }
                            }

                            TapHandler {
                                onTapped: categoryList.currentIndex = index
                            }
                            
                            HoverHandler {
                                id: hh
                                cursorShape: Qt.PointingHandCursor
                            }
                            
                            Rectangle {
                                anchors.fill: parent; radius: 12
                                color: "white"; opacity: hh.hovered && !ListView.isCurrentItem ? 0.04 : 0
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 12
                        color: Qt.rgba(1, 0, 0, 0.1)
                        border.color: Qt.rgba(1, 0, 0, 0.2)
                        border.width: 1
                        
                        Text {
                            anchors.centerIn: parent
                            text: "RESET DEFAULTS"
                            color: "#FF453A"
                            font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1
                        }
                        
                        TapHandler { onTapped: FrameConfig.reset() }
                    }
                }

                Rectangle {
                    anchors.right: parent.right; height: parent.height; width: 1
                    color: "white"; opacity: 0.05
                }
            }

            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 40
                    spacing: 24

                    Text {
                        text: FrameConfig.settingsStructure[categoryList.currentIndex].category
                        color: "white"
                        font.pixelSize: 32; font.weight: Font.Bold
                    }

                    ListView {
                        id: settingsList
                        Layout.fillWidth: true; Layout.fillHeight: true
                        
                        model: root.getModel()

                        clip: true
                        spacing: 20
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
                        footer: Item { height: 40 }
                        
                        Behavior on contentY { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

                        delegate: Loader {
                            width: (ListView.view && ListView.view.width) || 0
                            
                            property var safeData: {
                                if (!ListView.view || !ListView.view.model) return null;
                                var m = ListView.view.model;
                                if (index >= 0 && index < m.length) {
                                    return m[index];
                                }
                                return null;
                            }

                            sourceComponent: {
                                if (!safeData) return null;
                                switch (safeData.type) {
                                    case "header": return headerComp;
                                    case "slider": return sliderComp;
                                    case "color":  return colorComp;
                                    case "switch": return switchComp;
                                    default: return null;
                                }
                            }
                            
                            onLoaded: {
                                if (item && safeData) item.itemData = safeData
                            }
                            
                            onSafeDataChanged: {
                                if (item && safeData) item.itemData = safeData
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: headerComp
        Item {
            property var itemData
            height: 40; width: parent ? parent.width : 0
            Text {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                text: itemData ? itemData.label.toUpperCase() : ""
                color: FrameConfig.accentColor
                font.pixelSize: 11; font.weight: Font.Black; font.letterSpacing: 1.5; opacity: 0.5
            }
        }
    }

    Component {
        id: sliderComp
        ColumnLayout {
            property var itemData
            width: parent ? parent.width : 0; spacing: 8
            
            RowLayout {
                Layout.fillWidth: true
                Text { text: itemData ? itemData.label : ""; color: "white"; font.pixelSize: 15; opacity: 0.9 }
                Item { Layout.fillWidth: true }
                Text { 
                    text: itemData ? (itemData.step < 1 ? FrameConfig[itemData.property].toFixed(2) : Math.round(FrameConfig[itemData.property])) : ""
                    color: "white"; font.pixelSize: 13; font.weight: Font.Bold; opacity: 0.5 
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                color: "transparent"
                
                Slider {
                    anchors.fill: parent
                    anchors.leftMargin: 4; anchors.rightMargin: 4
                    
                    from: itemData ? itemData.min : 0
                    to: itemData ? itemData.max : 100
                    stepSize: itemData ? (itemData.step || 1) : 1
                    
                    value: itemData ? FrameConfig[itemData.property] : 0

                    onMoved: { FrameConfig[itemData.property] = value }
                    onPressedChanged: { if (!pressed) FrameConfig.save() }
                    
                    background: Rectangle {
                        width: parent.width
                        height: 6
                        radius: 3
                        color: "white"
                        opacity: 0.1
                        anchors.centerIn: parent
                        
                        Rectangle {
                            width: parent.parent.visualPosition * parent.width
                            height: parent.height
                            radius: 3
                            color: FrameConfig.accentColor
                        }
                    }
                    handle: Rectangle {
                        x: parent.visualPosition * (parent.availableWidth - width)
                        anchors.verticalCenter: parent.verticalCenter 
                        width: 20; height: 20; radius: 10; color: "white"
                        border.color: FrameConfig.accentColor; border.width: 1
                    }
                }
            }
        }
    }

    Component {
        id: switchComp
        RowLayout {
            property var itemData
            width: parent ? parent.width : 0; height: 40
            
            Text { text: itemData ? itemData.label : ""; color: "white"; font.pixelSize: 15; opacity: 0.9; Layout.fillWidth: true }
            
            Switch {
                Binding on checked {
                    value: itemData ? FrameConfig[itemData.property] : false
                    restoreMode: Binding.RestoreBindingOrValue
                }
                
                onToggled: { FrameConfig[itemData.property] = checked; FrameConfig.save() }
                
                indicator: Rectangle {
                    implicitWidth: 44; implicitHeight: 24; x: parent.leftPadding; y: parent.height / 2 - height / 2; radius: 12
                    color: parent.checked ? FrameConfig.accentColor : Qt.rgba(1, 1, 1, 0.1)
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Rectangle {
                        x: parent.parent.checked ? parent.width - width - 2 : 2; y: 2; width: 20; height: 20; radius: 10
                        color: parent.parent.checked ? FrameConfig.color : "white"
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    }
                }
            }
        }
    }

    Component {
        id: colorComp
        RowLayout {
            property var itemData
            width: parent ? parent.width : 0; spacing: 16
            
            Text { text: itemData ? itemData.label : ""; color: "white"; font.pixelSize: 15; opacity: 0.9; Layout.fillWidth: true }
            
            TextField {
                Layout.preferredWidth: 100
                color: "white"; font.pixelSize: 13; font.family: "Monospace"
                
                Binding on text {
                    value: itemData ? FrameConfig[itemData.property] : ""
                    restoreMode: Binding.RestoreBindingOrValue
                }

                background: Rectangle { 
                    color: "white"; opacity: 0.05; radius: 8
                    border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
                }
                onAccepted: { FrameConfig[itemData.property] = text; FrameConfig.save(); focus = false }
            }
            
            Rectangle {
                width: 36; height: 36; radius: 18
                color: itemData ? FrameConfig[itemData.property] : "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.2); border.width: 2
            }
        }
    }
}
