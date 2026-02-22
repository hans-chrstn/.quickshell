import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

Loader {
    id: root
    width: parent ? parent.width : 0
    
    property var itemData: null

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
        RowLayout {
            width: root.width; height: 44; spacing: 16
            Text { text: itemData ? itemData.label : ""; color: "white"; font.pixelSize: 15; opacity: 0.9; Layout.fillWidth: true }
            TextField {
                Layout.preferredWidth: 180
                color: "white"; font.pixelSize: 13; font.family: "Monospace"
                text: itemData ? FrameConfig[itemData.property] : ""
                background: Rectangle { 
                    color: "white"; opacity: 0.05; radius: 8
                    border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
                }
                onAccepted: { FrameConfig[itemData.property] = text; FrameConfig.save(); focus = false }
            }
        }
    }

    Component {
        id: headerComp
        Item {
            height: 40; width: root.width
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
            width: root.width; spacing: 8
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
                Layout.fillWidth: true; Layout.preferredHeight: 34; color: "transparent"
                Slider {
                    anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4
                    from: itemData ? itemData.min : 0
                    to: itemData ? itemData.max : 100
                    stepSize: itemData ? (itemData.step || 1) : 1
                    value: itemData ? FrameConfig[itemData.property] : 0
                    onMoved: { FrameConfig[itemData.property] = value }
                    onPressedChanged: { if (!pressed) FrameConfig.save() }
                    background: Rectangle {
                        width: parent.width; height: 6; radius: 3; color: "white"; opacity: 0.1; anchors.centerIn: parent
                        Rectangle {
                            width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 3; color: FrameConfig.accentColor
                        }
                    }
                    handle: Rectangle {
                        x: parent.visualPosition * (parent.availableWidth - width); anchors.verticalCenter: parent.verticalCenter 
                        width: 20; height: 20; radius: 10; color: "white"; border.color: FrameConfig.accentColor; border.width: 1
                        scale: parent.pressed ? 1.2 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150 } }
                    }
                }
            }
        }
    }

    Component {
        id: switchComp
        RowLayout {
            width: root.width; height: 40
            Text { text: itemData ? itemData.label : ""; color: "white"; font.pixelSize: 15; opacity: 0.9; Layout.fillWidth: true }
            Switch {
                checked: itemData ? FrameConfig[itemData.property] : false
                onToggled: { FrameConfig[itemData.property] = checked; FrameConfig.save() }
                indicator: Rectangle {
                    implicitWidth: 44; implicitHeight: 24; radius: 12
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
            width: root.width; spacing: 16
            Text { text: itemData ? itemData.label : ""; color: "white"; font.pixelSize: 15; opacity: 0.9; Layout.fillWidth: true }
            TextField {
                Layout.preferredWidth: 100; color: "white"; font.pixelSize: 13; font.family: "Monospace"
                text: itemData ? FrameConfig[itemData.property] : ""
                background: Rectangle { 
                    color: "white"; opacity: 0.05; radius: 8; border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
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
