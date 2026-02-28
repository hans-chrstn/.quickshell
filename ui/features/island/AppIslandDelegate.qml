import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import qs.core
import qs.ui.shared

Item {
    id: delegateRoot

    width: ThemeManager.appIslandDelegateWidth
    height: 60

    property bool isIslandExpanded: false
    readonly property var app: model.app

    readonly property bool isHovered: hHandler.hovered
    readonly property bool isRunning: app ? NiriManager.isApplicationRunning(app.id) : false
    
    readonly property real visualOffset: {
        var count = PathView.view.count;
        var dist = Math.abs(index - PathView.view.currentIndex);
        return Math.min(dist, count - dist);
    }
    
    property real cascadeY: 60
    property real cascadeRotation: 0
    property real cascadeOpacity: 0.0

    property real animScale: isHovered ? 1.25 : 1.0
    Behavior on animScale { NumberAnimation { duration: 450; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }

    property real animLift: isHovered ? -12 : 0
    Behavior on animLift { NumberAnimation { duration: 450; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }

    states: [
        State {
            name: "expanded"
            when: delegateRoot.isIslandExpanded
            PropertyChanges { target: delegateRoot; cascadeY: 0; cascadeRotation: 0; cascadeOpacity: 1.0 }
        },
        State {
            name: "collapsed"
            when: !delegateRoot.isIslandExpanded
            PropertyChanges { target: delegateRoot; cascadeY: 60; cascadeRotation: (index % 2 === 0 ? 10 : -10); cascadeOpacity: 0.0 }
        }
    ]

    transitions: [
        Transition {
            from: "collapsed"; to: "expanded"
            SequentialAnimation {
                PauseAnimation { duration: visualOffset * 80 }
                ParallelAnimation {
                    NumberAnimation { property: "cascadeY"; duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.8 }
                    NumberAnimation { property: "cascadeRotation"; duration: 600; easing.type: Easing.OutBack; easing.overshoot: 2.0 }
                    NumberAnimation { property: "cascadeOpacity"; duration: 300 }
                }
            }
        },
        Transition {
            from: "expanded"; to: "collapsed"
            ParallelAnimation {
                NumberAnimation { property: "cascadeY"; duration: 200 }
                NumberAnimation { property: "cascadeRotation"; duration: 200 }
                NumberAnimation { property: "cascadeOpacity"; duration: 200 }
            }
        }
    ]

    opacity: cascadeOpacity * PathView.itemOpacity
    z: delegateRoot.isIslandExpanded ? (100 - visualOffset) : 0

    HoverHandler {
        id: hHandler
        cursorShape: Qt.PointingHandCursor
    }

    ColumnLayout {
        id: mainLayout
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
        
        transform: [
            Scale {
                origin.x: ThemeManager.appIslandDelegateWidth / 2
                origin.y: ThemeManager.appIslandDelegateHeight / 2
                xScale: (mouseArea.pressed ? 0.9 : 1.0) * animScale
                yScale: xScale
            },
            Translate {
                y: animLift + cascadeY
            },
            Rotation {
                origin.x: ThemeManager.appIslandDelegateWidth / 2
                origin.y: ThemeManager.appIslandDelegateHeight / 2
                angle: cascadeRotation
            }
        ]

        Item {
            Layout.preferredWidth: Math.max(iconItem.Layout.preferredWidth, nameText.implicitWidth)
            Layout.preferredHeight: iconItem.Layout.preferredHeight + nameText.implicitHeight + mainLayout.spacing
            Layout.alignment: Qt.AlignHCenter

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        contextMenuLdr.active = true
                        if (contextMenuLdr.item) contextMenuLdr.item.popup()
                    } else {
                        if (isRunning) {
                            NiriManager.focusApplication(app.id)
                        } else {
                            if (app) app.execute()
                        }
                    }
                }
            }
            
            LazyLoader {
                id: contextMenuLdr
                active: false
                
                Menu {
                    id: contextMenu
                    parent: delegateRoot
                    width: 220
                    padding: 6
                    
                    property var windowsList: []
                    
                    onOpened: {
                        if (typeof appIslandRoot !== "undefined") appIslandRoot.activeMenus++
                        if (app) windowsList = NiriManager.getApplicationWindows(app.id)
                    }
                    onClosed: {
                        if (typeof appIslandRoot !== "undefined") appIslandRoot.activeMenus--
                        contextMenuLdr.active = false
                    }
                    
                    enter: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                            NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                        }
                    }
                    
                    exit: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 }
                            NumberAnimation { property: "scale"; from: 1; to: 0.95; duration: 150 }
                        }
                    }
                    
                    background: Rectangle {
                        color: ThemeManager.backgroundPrimaryColor
                        radius: 16
                        border.color: ThemeManager.outlinePrimaryColor
                        border.width: 1
                        opacity: 0.95
                        
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowOpacity: 0.5
                            shadowBlur: 20
                            shadowVerticalOffset: 6
                        }
                    }

                    Connections {
                        target: delegateRoot
                        function onIsIslandExpandedChanged() {
                            if (!delegateRoot.isIslandExpanded) contextMenu.close()
                        }
                    }

                    MenuItem {
                        id: newWinItem
                        implicitWidth: 208; implicitHeight: 36
                        
                        contentItem: RowLayout {
                            spacing: 10
                            StyledLabel { text: "󰐕"; type: "body"; customColor: newWinItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceVariantContentColor; Layout.leftMargin: 8 }
                            StyledLabel { text: "New Window"; type: "label"; font.weight: Font.Medium; customColor: newWinItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceContentColor; Layout.fillWidth: true }
                        }
                        background: Rectangle { color: newWinItem.highlighted ? ThemeManager.surfacePrimaryColor : "transparent"; radius: 10 }
                        onTriggered: if (app) app.execute()
                    }

                    Repeater {
                        model: contextMenu.windowsList
                        delegate: MenuItem {
                            id: winItem
                            implicitWidth: 208; implicitHeight: 36

                            contentItem: RowLayout {
                                spacing: 8
                                
                                StyledLabel { 
                                    text: "󰖯"
                                    type: "body"; customColor: winItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceVariantContentColor; Layout.leftMargin: 8 
                                }
                                
                                StyledLabel { 
                                    text: modelData.title
                                    type: "body"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    customColor: winItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceContentColor
                                    Layout.fillWidth: true
                                    elideMode: Text.ElideRight
                                }

                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: closeArea.containsMouse ? ThemeManager.dangerSurfaceColor : "transparent"
                                    Layout.rightMargin: 4
                                    
                                    StyledLabel { 
                                        text: "󰅖"
                                        type: "body"
                                        anchors.centerIn: parent
                                        customColor: closeArea.containsMouse ? ThemeManager.dangerPrimaryColor : (winItem.highlighted ? ThemeManager.contentOnBackgroundColor : ThemeManager.surfaceVariantContentColor)
                                        font.pixelSize: 14
                                    }
                                    
                                    MouseArea {
                                        id: closeArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            NiriManager.closeWindowById(modelData.id)
                                            contextMenu.close()
                                        }
                                    }
                                }
                            }
                            background: Rectangle { color: winItem.highlighted ? ThemeManager.surfacePrimaryColor : "transparent"; radius: 10 }
                            onTriggered: NiriManager.focusWindowById(modelData.id)
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Item {
                    id: iconItem
                    Layout.preferredWidth: ThemeManager.appIslandIconSize
                    Layout.preferredHeight: ThemeManager.appIslandIconSize
                    Layout.alignment: Qt.AlignHCenter
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: ThemeManager.accentColor
                        opacity: isHovered ? ThemeManager.visualHighlightOpacity * 4 : ThemeManager.visualHighlightOpacity
                        scale: isHovered ? 0.95 : 0.85
                        y: isHovered ? 18 : 4
                        z: -1
                        layer.enabled: isHovered
                        layer.effect: MultiEffect { blurEnabled: true; blur: 0.5 }
                        Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                        Behavior on opacity { NumberAnimation { duration: 400 } }
                        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                    }

                    LazyLoader {
                        id: iconLoader
                        loading: delegateRoot.visualOffset < 10
                        activeAsync: delegateRoot.visualOffset < 5
                        
                        Image {
                            id: appIcon
                            parent: iconItem
                            anchors.fill: parent
                            sourceSize: Qt.size(ThemeManager.appIslandIconSize * 2, ThemeManager.appIslandIconSize * 2) 
                            layer.enabled: isHovered
                            layer.effect: MultiEffect { brightness: 0.15; saturation: 0.1 }
                            source: {
                                if (!app || !app.icon) return "";
                                if (app.icon.startsWith("/")) return "file://" + app.icon;
                                if (app.icon === "utilities-system-monitor" || app.icon === "system-run") return "";
                                return Quickshell.iconPath(app.icon);
                            }
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                    
                    StyledLabel {
                        anchors.centerIn: parent
                        visible: !iconLoader.item || iconLoader.item.status !== Image.Ready
                        text: app ? app.name.substring(0, 1).toUpperCase() : "?"
                        type: "title"
                        font.weight: Font.Black
                        opacity: 0.2
                    }
                    
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -6
                        width: isRunning ? 12 : 0
                        height: 4; radius: 2
                        color: ThemeManager.contentOnBackgroundColor
                        opacity: isRunning ? 0.8 : 0.0
                        
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }

                StyledLabel {
                    id: nameText
                    text: app ? app.name : ""
                    type: "caption"
                    font.weight: Font.DemiBold
                    font.pixelSize: 10
                    Layout.preferredWidth: parent.width - 8
                    horizontalAlignment: Text.AlignHCenter
                    elideMode: Text.ElideRight
                    opacity: PathView.isCurrentItem ? 1.0 : 0.6
                }
            }
        }
    }
}
