import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import qs.config
import qs.components
import qs.modules.island

BaseIsland {
    id: root
    
    readonly property bool isCC: view.currentIndex === 5
    expandedWidth: isCC ? 480 : FrameConfig.dynamicIslandExpandedWidth
    expandedHeight: isCC ? 200 : FrameConfig.dynamicIslandExpandedHeight
    collapsedWidth: FrameConfig.dynamicIslandCollapsedWidth
    isTop: true
    isBottom: false
    isCorner: false

    f1Rotation: 0
    f1X: -radius + 1
    f1Y: 16

    f2Rotation: 270
    f2X: width - 1
    f2Y: 16

    property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property var notifServer: null
    property alias isInteracting: root.mouseHovered
    
    onMouseHoveredChanged: root.expanded = mouseHovered || view.dragging

    Item {
        anchors.fill: parent

        Loader {
            id: cavaLoader; anchors.bottom: indicatorsRow.top; anchors.bottomMargin: 14; anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 40; height: 24
            readonly property bool musicPlaying: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing
            readonly property bool musicTabActive: view.currentIndex === 1
            active: root.expanded && musicTabActive && musicPlaying
            source: "Cava.qml"; visible: active && opacity > 0; opacity: active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        PathView {
            id: view; anchors.fill: parent; anchors.topMargin: FrameConfig.pathViewTopMargin
            anchors.bottom: indicatorsRow.top; anchors.bottomMargin: FrameConfig.pathViewBottomMargin
            visible: parent.opacity > 0; model: tabModel
            pathItemCount: 3; snapMode: PathView.SnapOneItem; highlightRangeMode: PathView.StrictlyEnforceRange
            preferredHighlightBegin: 0.5; preferredHighlightEnd: 0.5; dragMargin: width / 2
            
            transform: Translate {
                y: root.expanded ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
            }
            
            onDraggingChanged: root.expanded = root.mouseHovered || dragging

            path: Path {
                startX: -view.width * 0.5; startY: view.height / 2
                PathAttribute { name: "itemOpacity"; value: 0.0 }
                PathLine { x: 0; y: view.height / 2 }
                PathAttribute { name: "itemOpacity"; value: 0.0 }
                PathLine { x: view.width * 0.5; y: view.height / 2 }
                PathAttribute { name: "itemOpacity"; value: 1.0 }
                PathLine { x: view.width; y: view.height / 2 }
                PathAttribute { name: "itemOpacity"; value: 0.0 }
                PathLine { x: view.width * 1.5; y: view.height / 2 }
                PathAttribute { name: "itemOpacity"; value: 0.0 }
            }
            delegate: Item {
                width: root.width - 40; height: view.height; opacity: PathView.itemOpacity
                Loader {
                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                    sourceComponent: {
                        if (!model) return null;
                        if (model.type === "timeDate") return timeDateComp
                        if (model.type === "music") return musicComp
                        if (model.type === "weather") return weatherComp
                        if (model.type === "battery") return batteryComp
                        if (model.type === "notif") return notifComp
                        if (model.type === "cc") return ccComp
                        return null
                    }
                }
            }
        }
        
        Row {
            id: indicatorsRow; anchors.bottom: parent.bottom; anchors.bottomMargin: FrameConfig.indicatorRowBottomMargin
            anchors.horizontalCenter: parent.horizontalCenter; spacing: FrameConfig.indicatorRowSpacing
            
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { 
                SequentialAnimation {
                    PauseAnimation { duration: root.expanded ? 200 : 0 }
                    NumberAnimation { duration: 300 } 
                }
            }

            Repeater { 
                model: tabModel.count
                Rectangle { 
                    width: view.currentIndex === index ? 12 : 4; height: 4; radius: 2; color: "white"
                    opacity: view.currentIndex === index ? 0.8 : 0.2
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                } 
            }
        }
    }
    
    Component { id: timeDateComp; TimeDate { } }
    Component { id: musicComp; Music { player: root.activePlayer } }
    Component { id: weatherComp; Weather { } }
    Component { id: batteryComp; Battery {} }
    Component { id: notifComp; Notification { server: root.notifServer } }
    Component { id: ccComp; ControlCenter { } }

    ListModel {
        id: tabModel
        function updateModel() {
            clear();
            append({ "type": "timeDate" })
            append({ "type": "music" })
            append({ "type": "notif" })
            try { if (UPower.displayDevice && UPower.displayDevice.type !== 0) append({ "type": "battery" }) } catch (e) {}
            if (FrameConfig.showWeather) append({ "type": "weather" })
            append({ "type": "cc" })
        }
        Component.onCompleted: updateModel()
    }
    
    Connections {
        target: FrameConfig
        function onShowWeatherChanged() { tabModel.updateModel() }
    }
}
