import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.config

Item {
    id: delegateRoot

    width: FrameConfig.appIslandDelegateWidth
    height: 60

    readonly property var app: model.app

    readonly property bool isHovered: hHandler.hovered
    
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
                onClicked: { if (app) app.execute(); }
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
