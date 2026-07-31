import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.core
import qs.ui.shared
import qs.ui.features.island
import qs.ui.features.island.dynamic

IslandSurface {
    id: dynamicIslandRoot

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

    property int activeMenus: 0

    // Declaratively bind expansion state so it stays open when hovered, moving, or when menus are active
    isExpanded: isHovered || (tabView && tabView.moving) || activeMenus > 0

    DynamicIslandLogic {
        id: islandLogic
        activePlayer: MusicManager.activePlayer
    }

    onIsExpandedChanged: {
        if (!isExpanded) {
            tabView.collapseSelectors()
        }
    }

    surfaceContent: Item {
        anchors.fill: parent

        Loader {
            id: cavaLoader
            anchors.bottom: pageIndicator.top
            anchors.bottomMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 40
            height: 24

            readonly property bool musicPlaying: MusicManager.activePlayer && MusicManager.activePlayer.playbackState === MprisPlaybackState.Playing
            readonly property bool musicTabActive: tabView.currentIndex === 1

            active: dynamicIslandRoot.isExpanded && musicTabActive && musicPlaying
            source: "music/AudioVisualizer.qml"
            visible: active && opacity > 0
            opacity: active ? 1 : 0
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        IslandTabView {
            id: tabView
            anchors.fill: parent
            logic: islandLogic
            transform: Translate {
                y: dynamicIslandRoot.isExpanded ? 0 : 15
                Behavior on y {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutExpo
                    }
                }
            }
        }

        TabPositionIndicator {
            id: pageIndicator
            anchors.bottom: parent.bottom
            anchors.bottomMargin: ThemeManager.indicatorRowBottomMargin
            tabCount: tabView.count
            currentTabIndex: tabView.currentIndex

            opacity: dynamicIslandRoot.isExpanded ? 1 : 0
            visible: opacity > 0.01
            
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation {
                        duration: dynamicIslandRoot.isExpanded ? 200 : 0
                    }
                    NumberAnimation {
                        duration: 300
                    }
                }
            }
        }
    }
}
