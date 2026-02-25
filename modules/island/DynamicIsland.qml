import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import qs.services
import qs.components
import qs.modules.island

BaseIsland {
    id: root
    
    expandedWidth: ThemeManager.dynamicIslandExpandedWidth
    expandedHeight: ThemeManager.dynamicIslandExpandedHeight
    collapsedWidth: ThemeManager.dynamicIslandCollapsedWidth
    isTop: true
    isBottom: false
    isCorner: false

    f1Rotation: 0
    f1X: -radius + 1
    f1Y: 16

    f2Rotation: 270
    f2X: width - 1
    f2Y: 16

    onMouseHoveredChanged: root.expanded = mouseHovered || tabView.moving

    Item {
        anchors.fill: parent

        Loader {
            id: cavaLoader; anchors.bottom: pageIndicator.top; anchors.bottomMargin: 14; anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 40; height: 24
            readonly property bool musicPlaying: MusicManager.activePlayer && MusicManager.activePlayer.playbackState === MprisPlaybackState.Playing
            
            readonly property bool musicTabActive: tabView.currentIndex === 1
            
            active: root.expanded && musicTabActive && musicPlaying
            source: "Cava.qml"; visible: active && opacity > 0; opacity: active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        IslandTabView {
            id: tabView
            anchors.fill: parent
            activePlayer: MusicManager.activePlayer            
            transform: Translate {
                y: root.expanded ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
            }
            onMovingChanged: root.expanded = root.mouseHovered || moving
        }
        
        PageIndicator {
            id: pageIndicator
            anchors.bottom: parent.bottom
            anchors.bottomMargin: ThemeManager.indicatorRowBottomMargin
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
