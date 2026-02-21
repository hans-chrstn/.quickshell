import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import qs.config
import qs.services

Item {
    id: delegateRoot

    width: FrameConfig.appIslandDelegateWidth
    height: 60

    readonly property var app: model.app

    readonly property bool isHovered: hHandler.hovered
    readonly property bool isRunning: app ? NiriService.isAppRunning(app.id) : false
    
    readonly property real visualOffset: {
        var count = PathView.view.count;
        var dist = Math.abs(index - PathView.view.currentIndex);
        return Math.min(dist, count - dist);
    }
    
    property real cascadeY: 60
    property real cascadeRotation: 0
    property real cascadeOpacity: 0.0

    states: [
        State {
            name: "expanded"
            when: appIslandRoot.expanded
            PropertyChanges { target: delegateRoot; cascadeY: 0; cascadeRotation: 0; cascadeOpacity: 1.0 }
        },
        State {
            name: "collapsed"
            when: !appIslandRoot.expanded
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
    z: appIslandRoot.expanded ? (100 - visualOffset) : 0

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
                origin.x: FrameConfig.appIslandDelegateWidth / 2
                origin.y: FrameConfig.appIslandDelegateHeight / 2
                xScale: mouseArea.pressed ? 0.9 : (isHovered ? 1.25 : 1.0)
                yScale: xScale
                Behavior on xScale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.7 } }
            },
            Translate {
                y: (isHovered ? -10 : 0) + cascadeY
            },
            Rotation {
                origin.x: FrameConfig.appIslandDelegateWidth / 2
                origin.y: FrameConfig.appIslandDelegateHeight / 2
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
                        contextMenu.popup()
                    } else {
                        if (isRunning) {
                            NiriService.focusApp(app.id)
                        } else {
                            if (app) app.execute()
                        }
                    }
                }
            }
            
            Menu {
                id: contextMenu
                width: 220
                padding: 6
                
                property var windowsList: []
                
                onOpened: {
                    appIslandRoot.activeMenus++
                    if (app) windowsList = NiriService.getAppWindows(app.id)
                }
                onClosed: appIslandRoot.activeMenus--
                
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
                    color: Qt.rgba(0.12, 0.12, 0.14, 0.95)
                    radius: 16
                    border.color: Qt.rgba(1,1,1,0.08)
                    border.width: 1
                    
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowOpacity: 0.5
                        shadowBlur: 20
                        shadowVerticalOffset: 6
                    }
                }

                MenuItem {
                    id: newWinItem
                    implicitWidth: 208; implicitHeight: 36
                    
                    contentItem: RowLayout {
                        spacing: 10
                        Text { text: "󰐕"; font.pixelSize: 16; color: newWinItem.highlighted ? "white" : "#AAAAAA"; Layout.leftMargin: 8 }
                        Text { text: "New Window"; color: newWinItem.highlighted ? "white" : "#CCCCCC"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
                    }
                    background: Rectangle { color: newWinItem.highlighted ? Qt.rgba(1,1,1,0.1) : "transparent"; radius: 10 }
                    onTriggered: if (app) app.execute()
                }

                Repeater {
                    model: contextMenu.windowsList
                    delegate: MenuItem {
                        id: winItem
                        implicitWidth: 208; implicitHeight: 36

                        contentItem: RowLayout {
                            spacing: 8
                            
                            Text { 
                                text: "󰖯"
                                font.pixelSize: 14; color: winItem.highlighted ? "white" : "#AAAAAA"; Layout.leftMargin: 8 
                            }
                            
                            Text { 
                                text: modelData.title
                                color: winItem.highlighted ? "white" : "#CCCCCC"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: closeArea.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.3) : "transparent"
                                Layout.rightMargin: 4
                                
                                Text { 
                                    text: "󰅖"
                                    anchors.centerIn: parent
                                    color: closeArea.containsMouse ? "#FF5555" : (winItem.highlighted ? "white" : "#AAAAAA")
                                    font.pixelSize: 14
                                }
                                
                                MouseArea {
                                    id: closeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        NiriService.closeWindow(modelData.id)
                                        contextMenu.close()
                                    }
                                }
                            }
                        }
                        background: Rectangle { color: winItem.highlighted ? Qt.rgba(1,1,1,0.1) : "transparent"; radius: 10 }
                        onTriggered: NiriService.focusWindow(modelData.id)
                    }
                }
                
                Connections {
                    target: appIslandRoot
                    function onExpandedChanged() {
                        if (!appIslandRoot.expanded) contextMenu.close()
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                Item {
                    id: iconItem
                    Layout.preferredWidth: FrameConfig.appIslandIconSize
                    Layout.preferredHeight: FrameConfig.appIslandIconSize
                    Layout.alignment: Qt.AlignHCenter
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: FrameConfig.highlightColor
                        opacity: isHovered ? FrameConfig.highlightOpacity * 4 : FrameConfig.highlightOpacity
                        scale: isHovered ? 0.95 : 0.85
                        y: isHovered ? 18 : 4
                        z: -1
                        layer.enabled: isHovered
                        layer.effect: MultiEffect { blurEnabled: true; blur: 0.5 }
                        Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                        Behavior on opacity { NumberAnimation { duration: 400 } }
                        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                    }

                    Image {
                        id: appIcon
                        anchors.fill: parent
                        sourceSize: Qt.size(FrameConfig.appIslandIconSize * 2, FrameConfig.appIslandIconSize * 2) 
                        layer.enabled: isHovered
                        layer.effect: MultiEffect { brightness: 0.15; saturation: 0.1 }
                        source: {
                            if (!app || !app.icon) return Quickshell.iconPath("system-run");
                            if (app.icon.startsWith("/")) return "file://" + app.icon;
                            return Quickshell.iconPath(app.icon);
                        }
                        fillMode: Image.PreserveAspectFit
                        onStatusChanged: { if (status === Image.Error) source = Quickshell.iconPath("system-run"); }
                    }
                    
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -6
                        width: isRunning ? 12 : 0
                        height: 4; radius: 2
                        color: "white"
                        opacity: isRunning ? 0.8 : 0.0
                        
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }

                Text {
                    id: nameText
                    text: app ? app.name : ""
                    color: "white"
                    font.pixelSize: 10; font.weight: Font.DemiBold
                    Layout.preferredWidth: parent.width - 8
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    opacity: PathView.isCurrentItem ? 1.0 : 0.6
                }
            }
        }
    }
}
