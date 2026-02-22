import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.modules.island

BaseIsland {
    id: appIslandRoot

    expandedWidth: FrameConfig.appIslandExpandedWidth
    expandedHeight: searchBar.active ? (FrameConfig.appIslandExpandedHeight + FrameConfig.appIslandSearchBarHeight + 10) : FrameConfig.appIslandExpandedHeight
    collapsedWidth: FrameConfig.dynamicIslandCollapsedWidth
    
    isTop: false
    isBottom: true
    isCorner: false

    f1Rotation: 90
    f1X: -radius + 1
    f1Y: height - barHeight - radius

    f2Rotation: 180
    f2X: width - 1
    f2Y: height - barHeight - radius

    property alias searchVisible: searchBar.active
    property alias isInteracting: appIslandRoot.mouseHovered
    property int activeMenus: 0
    
    onMouseHoveredChanged: {
        if (mouseHovered) {
            collapseTimer.stop()
            appIslandRoot.expanded = true
        } else if (!searchVisible && activeMenus === 0) {
            collapseTimer.restart()
        }
    }
    
    onActiveMenusChanged: {
        if (activeMenus > 0) {
            collapseTimer.stop()
            appIslandRoot.expanded = true
        } else if (!mouseHovered && !searchVisible) {
            collapseTimer.restart()
        }
    }
    
    onExpandedChanged: {
        if (!expanded) searchBar.active = false 
    }

    Timer { id: collapseTimer; interval: 300; onTriggered: appIslandRoot.expanded = false }

    Behavior on height {
        enabled: appIslandRoot.expanded
        NumberAnimation { duration: 400; easing.type: Easing.OutExpo }
    }

    Item {
        id: mainContainer
        anchors.fill: parent
        
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => mouse.accepted = true
        }
        
        AppListView {
            id: appListView
            anchors.fill: parent
            filterText: searchBar.text
            
            anchors.topMargin: searchBar.active ? (FrameConfig.appIslandSearchBarHeight + 8) : 0
            Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
        }

        SearchBar {
            id: searchBar
            onActiveChanged: if (!active) text = ""
        }
    }
}
