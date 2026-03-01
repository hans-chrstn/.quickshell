import QtQuick
import Quickshell
import qs.core
import qs.ui.shared
import qs.ui.features.island
import qs.ui.features.island.app

IslandSurface {
    id: appIslandRoot

    expandedWidth: ThemeManager.appIslandExpandedWidth
    expandedHeight: searchBar.isSearchActive ? (ThemeManager.appIslandExpandedHeight + ThemeManager.appIslandSearchBarHeight + 10) : ThemeManager.appIslandExpandedHeight
    collapsedWidth: ThemeManager.dynamicIslandCollapsedWidth

    isAtTop: false
    isAtBottom: true
    isInCorner: false

    firstFilletRotation: 90
    firstFilletX: -cornerRadius + 1
    firstFilletY: height - barHeight - cornerRadius

    secondFilletRotation: 180
    secondFilletX: width - 1
    secondFilletY: height - barHeight - cornerRadius

    property alias searchVisible: searchBar.isSearchActive
    property int activeMenus: 0

    onIsHoveredChanged: {
        if (isHovered) {
            collapseTimer.stop()
            appIslandRoot.isExpanded = true
        } else if (!searchVisible && activeMenus === 0) {
            collapseTimer.restart()
        }
    }

    onActiveMenusChanged: {
        if (activeMenus > 0) {
            collapseTimer.stop()
            appIslandRoot.isExpanded = true
        } else if (!isHovered && !searchVisible) {
            collapseTimer.restart()
        }
    }

    onIsExpandedChanged: {
        if (!isExpanded) {
            searchBar.isSearchActive = false
        }
    }

    AppListLogic {
        id: appListLogic
    }

    Timer {
        id: collapseTimer
        interval: 300
        onTriggered: {
            appIslandRoot.isExpanded = false
        }
    }

    Behavior on height {
        enabled: appIslandRoot.isExpanded
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutExpo
        }
    }

    surfaceContent: Item {
        id: mainContainer
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                mouse.accepted = true
            }
        }

        AppListView {
            id: appListView
            anchors.fill: parent
            logic: appListLogic
            filterText: searchBar.searchText
            isIslandExpanded: appIslandRoot.isExpanded

            anchors.topMargin: searchBar.isSearchActive ? (ThemeManager.appIslandSearchBarHeight + 8) : 0
            
            Behavior on anchors.topMargin {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutExpo
                }
            }
        }

        ApplicationSearchBar {
            id: searchBar
            onIsSearchActiveChanged: {
                if (!isSearchActive) {
                    searchText = ""
                }
            }
        }
    }
}
