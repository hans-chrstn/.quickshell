import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import qs.core
import qs.ui.shared
import qs.ui.features.island

IslandSurface {
    id: root
    
    expandedWidth: ThemeManager.dynamicIslandExpandedWidth
    expandedHeight: ThemeManager.dynamicIslandExpandedHeight
    collapsedWidth: ThemeManager.dynamicIslandCollapsedWidth
    isAtTop: true
    isAtBottom: false
    isInCorner: false

    firstFilletRotation: 0
    firstFilletX: -cornerRadius + 1
    firstFilletY: 16

    secondFilletRotation: 270
    secondFilletX: width - 1
    secondFilletY: 16

    onIsHoveredChanged: root.isExpanded = isHovered || tabView.moving

    surfaceContent: Item {
        anchors.fill: parent

        Loader {
            id: cavaLoader; anchors.bottom: pageIndicator.top; anchors.bottomMargin: 14; anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 40; height: 24
            readonly property bool musicPlaying: MusicManager.activePlayer && MusicManager.activePlayer.playbackState === MprisPlaybackState.Playing
            
            readonly property bool musicTabActive: tabView.currentIndex === 1
            
            active: root.isExpanded && musicTabActive && musicPlaying
            source: "AudioVisualizer.qml"; visible: active && opacity > 0; opacity: active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        IslandTabView {
            id: tabView
            anchors.fill: parent
            activePlayer: MusicManager.activePlayer            
            transform: Translate {
                y: root.isExpanded ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
            }
            onMovingChanged: root.isExpanded = root.isHovered || moving
        }
        
        TabPositionIndicator {
            id: pageIndicator
            anchors.bottom: parent.bottom
            anchors.bottomMargin: ThemeManager.indicatorRowBottomMargin
            tabCount: tabView.count
            currentTabIndex: tabView.currentIndex
            
            opacity: root.isExpanded ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { 
                SequentialAnimation {
                    PauseAnimation { duration: root.isExpanded ? 200 : 0 }
                    NumberAnimation { duration: 300 } 
                }
            }
        }
    }
}
