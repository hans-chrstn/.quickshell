import QtQuick
import qs.components
import qs.core
import qs.services.settings

Item {
    id: root

    property QtObject context: null
    focus: true

    Component.onCompleted: focusRetrier.startFocus()

    FocusRetrier {
        id: focusRetrier
        targetItem: root
        activeService: SettingsService
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (SettingsService.currentSubpage.length > 0)
                SettingsService.currentSubpage = ""
            else
                SettingsService.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            SettingsService.selectedCategory = Math.max(
                0, SettingsService.selectedCategory - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            SettingsService.selectedCategory = Math.min(
                SettingsService.categories.length - 1,
                SettingsService.selectedCategory + 1)
            event.accepted = true
        }
    }

    SettingsCategoryRail {
        id: categoryRail
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 120
    }

    Rectangle {
        id: divider
        anchors.left: categoryRail.right
        anchors.leftMargin: 10
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Design.separator
    }

    Loader {
        anchors.left: divider.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        sourceComponent: {
            switch (SettingsService.currentSubpage) {
            case "wallpaper": return wallpaperPage
            case "island_style": return islandStylePage
            case "motion": return motionPage
            case "behavior": return behaviorPage
            default: return subpageMenuPage
            }
        }
    }

    Component {
        id: subpageMenuPage
        SettingsSubpageMenu {}
    }

    Component {
        id: motionPage
        MotionSettingsPage {}
    }

    Component {
        id: behaviorPage
        BehaviorSettingsPage {}
    }

    Component {
        id: wallpaperPage
        WallpaperSettingsPage {}
    }

    Component {
        id: islandStylePage
        IslandStylePage {}
    }
}
