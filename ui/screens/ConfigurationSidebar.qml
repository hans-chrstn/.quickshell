import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

FocusScope {
    id: root
    
    width: 240
    
    property alias currentCategoryIndex: categoryListView.currentIndex

    Keys.onUpPressed: {
        if (resetButton.activeFocus) {
            categoryListView.forceActiveFocus()
            categoryListView.currentIndex = categoryListView.count - 1
        } else {
            categoryListView.decrementCurrentIndex()
        }
    }
    
    Keys.onDownPressed: {
        if (categoryListView.activeFocus && categoryListView.currentIndex === categoryListView.count - 1) {
            resetButton.forceActiveFocus()
        } else {
            categoryListView.incrementCurrentIndex()
        }
    }
    
    KeyNavigation.right: settingsListScope

    Rectangle {
        anchors.fill: parent
        color: ThemeManager.surfaceSubtleColor
    }

    Connections {
        target: root.Window.window
        function onVisibleChanged() {
            if (target.visible) {
                appearanceRippleTimer.restart()
                categoryListView.forceActiveFocus()
            } else {
                isCascadeAnimationActive = false
            }
        }
    }

    Connections {
        target: ViewManager
        function onIsSettingsClosingChanged() {
            if (ViewManager.isSettingsClosing) {
                isCascadeAnimationActive = false
            }
        }
    }

    property bool isCascadeAnimationActive: false
    property real sidebarItemOpacity: (isCascadeAnimationActive && !ViewManager.isSettingsClosing) ? 1.0 : 0
    Behavior on sidebarItemOpacity { 
        NumberAnimation { 
            duration: 300 
        } 
    }

    Timer {
        id: appearanceRippleTimer
        interval: 50
        onTriggered: isCascadeAnimationActive = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Text {
            id: sidebarHeaderLabel
            text: "SETTINGS"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 12
            font.weight: Font.Black
            font.letterSpacing: 2
            opacity: 0.4 * root.sidebarItemOpacity
            Layout.margins: 16
            
            transform: Translate {
                x: root.isCascadeAnimationActive ? 0 : -20
                Behavior on x { 
                    NumberAnimation { 
                        duration: 500
                        easing.type: Easing.OutExpo 
                    } 
                }
            }
        }

        ListView {
            id: categoryListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: ThemeManager.settingsStructure
            clip: true
            currentIndex: 0
            spacing: 4
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            
            footer: Item { 
                height: 20 
            }
            
            focus: true
            activeFocusOnTab: false
            
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
            
            Behavior on contentY { 
                NumberAnimation { 
                    duration: 200
                    easing.type: Easing.OutQuart 
                } 
            }
            
            delegate: BaseButton {
                id: categoryItemDelegate
                width: categoryListView.width
                height: 48
                onClicked: {
                    categoryListView.currentIndex = index
                    categoryListView.forceActiveFocus()
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    
                    color: ListView.isCurrentItem ? ThemeManager.surfaceVariantColor : "transparent"
                    opacity: root.sidebarItemOpacity
                    Behavior on color { ColorAnimation { duration: 200 } }

                    transform: Translate {
                        x: (root.isCascadeAnimationActive && !ViewManager.isSettingsClosing) ? 0 : -40
                        Behavior on x { 
                            SequentialAnimation {
                                PauseAnimation { 
                                    duration: (root.isCascadeAnimationActive && !ViewManager.isSettingsClosing) ? (index * 35) : ((categoryListView.count - index) * 15) 
                                }
                                NumberAnimation { 
                                    duration: (root.isCascadeAnimationActive && !ViewManager.isSettingsClosing) ? 500 : 150
                                    easing.type: Easing.OutExpo 
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 4
                        width: (ListView.isCurrentItem && categoryListView.activeFocus) ? 4 : 0
                        height: 24
                        radius: 2
                        color: ThemeManager.primaryColor
                        Behavior on width { 
                            NumberAnimation { 
                                duration: 200
                                easing.type: Easing.OutBack 
                            } 
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        spacing: 12
                        
                        Item {
                            width: 28
                            height: parent.height
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: ThemeManager.contentOnBackgroundColor
                                font.pixelSize: 20
                                opacity: ListView.isCurrentItem ? 1.0 : 0.4
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }
                        }
                        
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.category
                            color: ThemeManager.contentOnBackgroundColor
                            font.pixelSize: 14
                            font.weight: ListView.isCurrentItem ? Font.DemiBold : Font.Normal
                            opacity: ListView.isCurrentItem ? 1.0 : 0.6
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: ThemeManager.contentOnBackgroundColor
                        opacity: categoryItemDelegate.isHovered && !ListView.isCurrentItem ? 0.04 : 0
                    }
                }
            }
        }

        BaseButton {
            id: resetBtnWrapper
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            onClicked: ThemeManager.resetToDefaults()
            
            Rectangle {
                id: resetButton
                anchors.fill: parent
                radius: 12
                color: ThemeManager.dangerSurfaceColor
                border.color: resetBtnWrapper.activeFocus ? "white" : ThemeManager.outlinePrimaryColor
                border.width: resetBtnWrapper.activeFocus ? 2 : 1
                opacity: root.sidebarItemOpacity
                
                transform: Translate {
                    x: (root.isCascadeAnimationActive && !ViewManager.isSettingsClosing) ? 0 : -40
                    Behavior on x { 
                        SequentialAnimation {
                            PauseAnimation { 
                                duration: (root.isCascadeAnimationActive && !ViewManager.isSettingsClosing) ? 300 : 0 
                            }
                            NumberAnimation { 
                                duration: 400
                                easing.type: Easing.OutExpo 
                            }
                        }
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "RESET DEFAULTS"
                    color: ThemeManager.dangerPrimaryColor
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1
                }
                
                Rectangle { 
                    anchors.fill: parent
                    color: ThemeManager.contentOnBackgroundColor
                    opacity: resetBtnWrapper.isHovered ? 0.1 : 0
                    radius: 12 
                }
            }
        }
    }

    Rectangle {
        anchors.right: parent.right
        height: parent.height
        width: 1
        color: ThemeManager.contentOnBackgroundColor
        opacity: 0.05
    }
}
