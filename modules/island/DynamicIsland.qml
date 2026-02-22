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
    
    readonly property bool isCC: tabView.currentIndex === 5
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
    property alias isInteracting: root.mouseHovered
    
    onMouseHoveredChanged: root.expanded = mouseHovered || tabView.moving

    Item {
        anchors.fill: parent
        
        Loader {
            id: cavaLoader; anchors.bottom: pageIndicator.top; anchors.bottomMargin: 14; anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 40; height: 24
            readonly property bool musicPlaying: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing
            readonly property bool musicTabActive: tabView.currentIndex === 1
            active: root.expanded && musicTabActive && musicPlaying
            source: "Cava.qml"; visible: active && opacity > 0; opacity: active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        IslandTabView {
            id: tabView
            anchors.fill: parent
            activePlayer: root.activePlayer
            
            transform: Translate {
                y: root.expanded ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
            }
            
            onMovingChanged: root.expanded = root.mouseHovered || moving
        }
        
        PageIndicator {
            id: pageIndicator
            anchors.bottom: parent.bottom
            anchors.bottomMargin: FrameConfig.indicatorRowBottomMargin
            count: tabView.count
            currentIndex: tabView.currentIndex
            
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { 
                SequentialAnimation {
                    PauseAnimation { duration: root.expanded ? 200 : 0 }
                    NumberAnimation { duration: 300 } 
                }
            }
        }
    }
}
