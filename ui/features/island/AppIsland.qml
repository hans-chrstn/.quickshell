import QtQuick
import Quickshell
import qs.core
import qs.ui.shared
import qs.ui.features.island
import qs.ui.features.island.app

IslandSurface {
    id: appIslandRoot

    expandedWidth: ThemeManager.appIslandExpandedWidth
    expandedHeight: ThemeManager.appIslandExpandedHeight
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

    property int activeMenus: 0

    onIsHoveredChanged: {
        if (isHovered) {
            collapseTimer.stop()
            appIslandRoot.isExpanded = true
        } else if (activeMenus === 0) {
            collapseTimer.restart()
        }
    }

    onActiveMenusChanged: {
        if (activeMenus > 0) {
            collapseTimer.stop()
            appIslandRoot.isExpanded = true
        } else if (!isHovered) {
            collapseTimer.restart()
        }
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
            isIslandExpanded: appIslandRoot.isExpanded
        }

        ApplicationSearchBar {
            id: searchBar
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
