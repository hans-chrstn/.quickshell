import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import qs.core
import qs.ui.shared

Menu {
    id: root
    
    property var app: null
    property var delegateRoot: null
    property var windowsList: []
    
    width: 240
    padding: 8
    
    onOpened: {
        if (typeof appIslandRoot !== "undefined") {
            appIslandRoot.activeMenus++
        }
        if (root.app) {
            root.windowsList = NiriManager.getApplicationWindows(root.app.id)
        }
    }
    
    onClosed: {
        if (typeof appIslandRoot !== "undefined") {
            appIslandRoot.activeMenus--
        }
    }
    
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { 
                property: "opacity"
                from: 0
                to: 1
                duration: 250
                easing.type: Easing.OutCubic
            }
            NumberAnimation { 
                property: "scale"
                from: 0.95
                to: 1
                duration: 250
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
        }
    }
    
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { 
                property: "opacity"
                from: 1
                to: 0
                duration: 150 
            }
            NumberAnimation { 
                property: "scale"
                from: 1
                to: 0.98
                duration: 150 
            }
        }
    }
    
    background: Rectangle {
        color: ThemeManager.backgroundPrimaryColor
        radius: 20
        border.color: ThemeManager.outlineStrongColor
        border.width: 1
        opacity: 0.98
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowOpacity: 0.6
            shadowBlur: 25
            shadowVerticalOffset: 8
        }
    }

    Connections {
        target: root.delegateRoot ? root.delegateRoot : null
        ignoreUnknownSignals: true
        
        function onIsIslandExpandedChanged() {
            if (root.delegateRoot && !root.delegateRoot.isIslandExpanded) {
                root.close()
            }
        }
    }

    StyledLabel {
        text: root.app ? root.app.name.toUpperCase() : "APPLICATION"
        type: "caption"
        font.weight: Font.Black
        font.pixelSize: 8
        letterSpacing: 1.5
        opacity: 0.4
        Layout.alignment: Qt.AlignHCenter
        horizontalAlignment: Text.AlignHCenter
        width: parent.width
        topPadding: 4
        bottomPadding: 8
    }

    StyledLabel {
        visible: root.windowsList.length > 0
        height: visible ? implicitHeight : 0
        text: "RUNNING WINDOWS"
        type: "caption"
        font.weight: Font.Black
        font.pixelSize: 7
        letterSpacing: 1
        opacity: 0.3
        leftPadding: 12
        bottomPadding: 4
    }

    Repeater {
        model: root.windowsList
        delegate: MenuItem {
            id: winItem
            implicitWidth: 224
            implicitHeight: 40

            contentItem: RowLayout {
                spacing: 10
                
                StyledLabel { 
                    text: ThemeManager.iconWindow
                    type: "body"
                    font.pixelSize: 14
                    customColor: winItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceVariantContentColor
                    Layout.leftMargin: 10
                }
                
                StyledLabel { 
                    text: modelData.title || "Untitled Window"
                    type: "body"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    customColor: winItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceContentColor
                    Layout.fillWidth: true
                    elideMode: Text.ElideRight
                }

                BaseButton {
                    id: closeBtn
                    width: 28
                    height: 28
                    Layout.rightMargin: 6
                    onClicked: {
                        NiriManager.closeWindowById(modelData.id)
                        root.close()
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: closeBtn.isHovered ? ThemeManager.dangerSurfaceColor : "transparent"
                        
                        StyledLabel { 
                            text: ThemeManager.iconClose
                            type: "body"
                            anchors.centerIn: parent
                            customColor: closeBtn.isHovered ? ThemeManager.dangerPrimaryColor : (winItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceVariantContentColor)
                            font.pixelSize: 14
                        }
                    }
                }
            }
            
            background: Rectangle { 
                color: winItem.highlighted ? ThemeManager.surfaceVariantStrongColor : "transparent"
                radius: 12 
            }
            
            onTriggered: {
                NiriManager.focusWindowById(modelData.id)
            }
        }
    }

    MenuSeparator {
        visible: root.windowsList.length > 0
        height: visible ? implicitHeight : 0
        contentItem: Rectangle {
            implicitWidth: 200
            implicitHeight: root.windowsList.length > 0 ? 1 : 0
            color: ThemeManager.contentOnBackgroundColor
            opacity: 0.05
        }
    }

    MenuItem {
        id: newWinItem
        implicitWidth: 224
        implicitHeight: 40
        
        contentItem: RowLayout {
            spacing: 12
            
            StyledLabel { 
                text: ThemeManager.iconAppNew
                type: "body"
                font.pixelSize: 16
                customColor: newWinItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.accentColor
                Layout.leftMargin: 10
            }
            
            StyledLabel { 
                text: "Launch New Instance"
                type: "label"
                font.weight: Font.DemiBold
                customColor: newWinItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceContentColor
                Layout.fillWidth: true 
            }
        }
        
        background: Rectangle { 
            color: newWinItem.highlighted ? ThemeManager.surfaceVariantStrongColor : "transparent"
            radius: 12 
        }
        
        onTriggered: {
            if (root.app) {
                root.app.execute()
            }
        }
    }

    MenuItem {
        id: locationItem
        implicitWidth: 224
        implicitHeight: 40
        
        contentItem: RowLayout {
            spacing: 12
            
            StyledLabel { 
                text: ThemeManager.iconAppLocation
                type: "body"
                font.pixelSize: 16
                customColor: locationItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceVariantContentColor
                Layout.leftMargin: 10
            }
            
            StyledLabel { 
                text: "Open Desktop Entry"
                type: "label"
                font.weight: Font.Medium
                customColor: locationItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceContentColor
                Layout.fillWidth: true 
            }
        }
        
        background: Rectangle { 
            color: locationItem.highlighted ? ThemeManager.surfaceVariantStrongColor : "transparent"
            radius: 12 
        }
        
        onTriggered: {
            if (root.app) {
                Quickshell.execDetached(["xdg-open", root.app.path])
            }
        }
    }

    MenuItem {
        id: infoItem
        implicitWidth: 224
        implicitHeight: 40
        
        contentItem: RowLayout {
            spacing: 12
            
            StyledLabel { 
                text: ThemeManager.iconAppDetails
                type: "body"
                font.pixelSize: 16
                customColor: infoItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceVariantContentColor
                Layout.leftMargin: 10
            }
            
            StyledLabel { 
                text: "Application Details"
                type: "label"
                font.weight: Font.Medium
                customColor: infoItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceContentColor
                Layout.fillWidth: true 
            }
        }
        
        background: Rectangle { 
            color: infoItem.highlighted ? ThemeManager.surfaceVariantStrongColor : "transparent"
            radius: 12 
        }
        
        onTriggered: {
            if (root.app) {
                Quickshell.execDetached(["notify-send", root.app.name, "ID: " + root.app.id + "\nPath: " + root.app.path])
            }
        }
    }
}
