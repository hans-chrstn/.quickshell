import QtQuick
import QtQuick.Layouts
import qs.services

FocusScope {
    id: root
    width: 240
    
    property alias currentIndex: categoryList.currentIndex

    Keys.onUpPressed: {
        if (resetBtn.activeFocus) {
            categoryList.forceActiveFocus()
            categoryList.currentIndex = categoryList.count - 1
        } else {
            categoryList.decrementCurrentIndex()
        }
    }
    
    Keys.onDownPressed: {
        if (categoryList.activeFocus && categoryList.currentIndex === categoryList.count - 1) {
            resetBtn.forceActiveFocus()
        } else {
            categoryList.incrementCurrentIndex()
        }
    }
    
    KeyNavigation.right: settingsListScope

    Rectangle {
        anchors.fill: parent
        color: ThemeService.surfaceSubtle
    }

    Connections {
        target: root.Window.window
        function onVisibleChanged() {
            if (target.visible) {
                rippleTimer.restart()
                categoryList.forceActiveFocus()
            } else {
                cascadeActive = false
            }
        }
    }

    Connections {
        target: ViewService
        function onClosingSettingsChanged() {
            if (ViewService.closingSettings) {
                cascadeActive = false
            }
        }
    }

    property bool cascadeActive: false
    property real itemOpacity: (cascadeActive && !ViewService.closingSettings) ? 1.0 : 0
    Behavior on itemOpacity { NumberAnimation { duration: 300 } }

    Timer {
        id: rippleTimer
        interval: 50
        onTriggered: cascadeActive = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Text {
            id: headerText
            text: "SETTINGS"
            color: ThemeService.backgroundContent
            font.pixelSize: 12; font.weight: Font.Black; font.letterSpacing: 2
            opacity: 0.4 * root.itemOpacity
            Layout.margins: 16
            
            transform: Translate {
                x: root.cascadeActive ? 0 : -20
                Behavior on x { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
            }
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
            
            focus: true
            activeFocusOnTab: false
            
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
            
            Behavior on contentY { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
            
            delegate: Rectangle {
                id: itemDelegate
                width: categoryList.width
                height: 48; radius: 12
                
                color: ListView.isCurrentItem ? ThemeService.surfaceVariant : "transparent"
                opacity: root.itemOpacity
                Behavior on color { ColorAnimation { duration: 200 } }

                transform: Translate {
                    x: (root.cascadeActive && !ViewService.closingSettings) ? 0 : -40
                    Behavior on x { 
                        SequentialAnimation {
                            PauseAnimation { 
                                duration: (root.cascadeActive && !ViewService.closingSettings) ? (index * 35) : ((categoryList.count - index) * 15) 
                            }
                            NumberAnimation { 
                                duration: (root.cascadeActive && !ViewService.closingSettings) ? 500 : 150
                                easing.type: Easing.OutExpo 
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 4
                    width: (ListView.isCurrentItem && categoryList.activeFocus) ? 4 : 0
                    height: 24; radius: 2
                    color: ThemeService.primaryMain
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                }

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
                    onTapped: {
                        categoryList.currentIndex = index
                        categoryList.forceActiveFocus()
                    }
                }
                
                HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
                
                Rectangle {
                    anchors.fill: parent; radius: 12
                    color: ThemeService.backgroundContent; opacity: hh.hovered && !ListView.isCurrentItem ? 0.04 : 0
                }
            }
        }

        Rectangle {
            id: resetBtn
            Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 12
            color: ThemeService.dangerSurface
            border.color: activeFocus ? "white" : ThemeService.outlineMain
            border.width: activeFocus ? 2 : 1
            opacity: root.itemOpacity
            
            focus: true
            Keys.onSpacePressed: ThemeService.reset()
            Keys.onEnterPressed: ThemeService.reset()
            Keys.onReturnPressed: ThemeService.reset()

            transform: Translate {
                x: (root.cascadeActive && !ViewService.closingSettings) ? 0 : -40
                Behavior on x { 
                    SequentialAnimation {
                        PauseAnimation { duration: (root.cascadeActive && !ViewService.closingSettings) ? 300 : 0 }
                        NumberAnimation { duration: 400; easing.type: Easing.OutExpo }
                    }
                }
            }
            
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
