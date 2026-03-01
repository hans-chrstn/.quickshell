import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

FocusScope {
    id: root
    
    width: 240
    
    property alias currentCategoryIndex: categoryListView.currentIndex

    Keys.onUpPressed: {
        if (resetBtnWrapper.activeFocus) {
            categoryListView.forceActiveFocus()
            categoryListView.currentIndex = categoryListView.count - 1
        } else {
            categoryListView.decrementCurrentIndex()
        }
    }
    
    Keys.onDownPressed: {
        if (categoryListView.activeFocus && categoryListView.currentIndex === categoryListView.count - 1) {
            resetBtnWrapper.forceActiveFocus()
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
        onTriggered: {
            isCascadeAnimationActive = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        StyledLabel {
            id: sidebarHeaderLabel
            text: "SETTINGS"
            type: "sidebarHeader"
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
            clip: false
            currentIndex: 0
            spacing: 4
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            
            footer: Item { 
                height: 20 
            }
            
            focus: true
            activeFocusOnTab: false
            
            onCurrentIndexChanged: {
                positionViewAtIndex(currentIndex, ListView.Contain)
            }
            
            Behavior on contentY { 
                NumberAnimation { 
                    duration: 200
                    easing.type: Easing.OutQuart 
                } 
            }
            
            delegate: ConfigurationSidebarDelegate {
                modelData: model.modelData
                isCascadeAnimationActive: root.isCascadeAnimationActive
                isSettingsClosing: ViewManager.isSettingsClosing
                sidebarItemOpacity: root.sidebarItemOpacity
            }
        }

        BaseButton {
            id: resetBtnWrapper
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            onClicked: {
                ThemeManager.resetToDefaults()
            }
            
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
                
                StyledLabel {
                    anchors.centerIn: parent
                    text: "RESET DEFAULTS"
                    type: "caption"
                    customColor: ThemeManager.dangerPrimaryColor
                    font.weight: Font.Bold
                    letterSpacing: 1
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
