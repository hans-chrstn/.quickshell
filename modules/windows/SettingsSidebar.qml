import QtQuick
import QtQuick.Layouts
import qs.services

Rectangle {
    id: root
    width: 240
    color: ThemeService.surfaceSubtle
    
    property alias currentIndex: categoryList.currentIndex

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Text {
            text: "SETTINGS"
            color: ThemeService.backgroundContent
            font.pixelSize: 12; font.weight: Font.Black; font.letterSpacing: 2
            opacity: 0.4
            Layout.margins: 16
        }

        ListView {
            id: categoryList
            Layout.fillWidth: true; Layout.fillHeight: true
            model: ThemeService.settingsStructure
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
                color: ListView.isCurrentItem ? ThemeService.surfaceVariant : "transparent"
                
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16; spacing: 12
                    
                    Item {
                        width: 28; height: parent.height
                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: ThemeService.backgroundContent
                            font.pixelSize: 20
                            opacity: ListView.isCurrentItem ? 1.0 : 0.4
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.category
                        color: ThemeService.backgroundContent
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
                    color: ThemeService.backgroundContent; opacity: hh.hovered && !ListView.isCurrentItem ? 0.04 : 0
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 12
            color: ThemeService.dangerSurface
            border.color: ThemeService.outlineMain
            border.width: 1
            
            Text {
                anchors.centerIn: parent
                text: "RESET DEFAULTS"
                color: ThemeService.dangerMain
                font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1
            }
            
            TapHandler { onTapped: ThemeService.reset() }
            
            HoverHandler { id: rhh; cursorShape: Qt.PointingHandCursor }
            Rectangle { anchors.fill: parent; color: ThemeService.backgroundContent; opacity: rhh.hovered ? 0.1 : 0; radius: 12 }
        }
    }

    Rectangle {
        anchors.right: parent.right; height: parent.height; width: 1
        color: ThemeService.backgroundContent; opacity: 0.05
    }
}