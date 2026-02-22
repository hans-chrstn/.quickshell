import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services

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
            Text { text: itemData ? itemData.label : ""; color: ThemeService.backgroundContent; font.pixelSize: 15; opacity: 0.9; Layout.fillWidth: true }
            TextField {
                Layout.preferredWidth: 180
                color: ThemeService.backgroundContent; font.pixelSize: 13; font.family: "Monospace"
                text: itemData ? ThemeService[itemData.property] : ""
                background: Rectangle { 
                    color: ThemeService.backgroundContent; opacity: 0.05; radius: 8
                    border.color: ThemeService.outlineMain; border.width: 1
                }
                onAccepted: { ThemeService[itemData.property] = text; ThemeService.save(); focus = false }
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
                color: ThemeService.accentColor
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
                Text { text: itemData ? itemData.label : ""; color: ThemeService.backgroundContent; font.pixelSize: 15; opacity: 0.9 }
                Item { Layout.fillWidth: true }
                Text { 
                    text: itemData ? (itemData.step < 1 ? ThemeService[itemData.property].toFixed(2) : Math.round(ThemeService[itemData.property])) : ""
                    color: ThemeService.backgroundContent; font.pixelSize: 13; font.weight: Font.Bold; opacity: 0.5 
                }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 34; color: "transparent"
                Slider {
                    anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4
                    from: itemData ? itemData.min : 0
                    to: itemData ? itemData.max : 100
                    stepSize: itemData ? (itemData.step || 1) : 1
                    value: itemData ? ThemeService[itemData.property] : 0
                    onMoved: { ThemeService[itemData.property] = value }
                    onPressedChanged: { if (!pressed) ThemeService.save() }
                    background: Rectangle {
                        width: parent.width; height: 6; radius: 3; color: ThemeService.backgroundContent; opacity: 0.1; anchors.centerIn: parent
                        Rectangle {
                            width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 3; color: ThemeService.accentColor
                        }
                    }
                    handle: Rectangle {
                        x: parent.visualPosition * (parent.availableWidth - width); anchors.verticalCenter: parent.verticalCenter 
                        width: 20; height: 20; radius: 10; color: ThemeService.backgroundContent; border.color: ThemeService.accentColor; border.width: 1
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
            Text { text: itemData ? itemData.label : ""; color: ThemeService.backgroundContent; font.pixelSize: 15; opacity: 0.9; Layout.fillWidth: true }
            Switch {
                checked: itemData ? ThemeService[itemData.property] : false
                onToggled: { ThemeService[itemData.property] = checked; ThemeService.save() }
                indicator: Rectangle {
                    implicitWidth: 44; implicitHeight: 24; radius: 12
                    color: parent.checked ? ThemeService.accentColor : ThemeService.outlineMain
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Rectangle {
                        x: parent.parent.checked ? parent.width - width - 2 : 2; y: 2; width: 20; height: 20; radius: 10
                        color: parent.parent.checked ? ThemeService.backgroundMain : ThemeService.backgroundContent
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
            Text { text: itemData ? itemData.label : ""; color: ThemeService.backgroundContent; font.pixelSize: 15; opacity: 0.9; Layout.fillWidth: true }
            TextField {
                Layout.preferredWidth: 100; color: ThemeService.backgroundContent; font.pixelSize: 13; font.family: "Monospace"
                text: itemData ? ThemeService[itemData.property] : ""
                background: Rectangle { 
                    color: ThemeService.backgroundContent; opacity: 0.05; radius: 8; border.color: ThemeService.outlineMain; border.width: 1
                }
                onAccepted: { ThemeService[itemData.property] = text; ThemeService.save(); focus = false }
            }
            Rectangle {
                width: 36; height: 36; radius: 18
                color: itemData ? ThemeService[itemData.property] : "transparent"
                border.color: ThemeService.outlineStrong; border.width: 2
            }
        }
    }
}
