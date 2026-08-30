import QtQuick
import qs.components
import qs.components.lifecycle
import qs.core
import qs.services.settings

Item {
    id: root

    property QtObject context: null
    readonly property string screenName: context?.screenName ?? ""
    focus: true

    Component.onCompleted: focusRetrier.startFocus()

    FocusRetrier {
        id: focusRetrier
        targetItem: root
        activeService: SettingsService
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (SettingsService.currentPage.length > 0)
                SettingsService.back()
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

    LifecycleLoader {
        anchors.left: divider.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        resourceId: "settings.page." + root.screenName + "."
            + (SettingsService.currentPage.length > 0
                ? SettingsService.currentPage : "category-menu")
        owner: "settings.module." + root.screenName
        restorationSource: "SettingsService route and ConfigService"
        classification: "active-only"
        registrationEnabled: root.screenName.length > 0
        requestedActive: true
        retentionReason: "selected-route"
        evictionReason: ""
        sourceComponent: {
            switch (SettingsService.currentPage) {
            case "wallpaper": return wallpaperPage
            case "wallpaper_options": return wallpaperOptionsPage
            case "wallpaper_optimization": return wallpaperOptimizationPage
            case "wallpaper_cache": return wallpaperCachePage
            case "wallpaper_directory": return wallpaperDirectoryPage
            case "island_style": return islandStylePage
            case "motion": return motionPage
            case "behavior": return behaviorPage
            case "analytics_lifecycle": return analyticsLifecyclePage
            case "analytics_wallpaper": return analyticsWallpaperPage
            case "analytics_performance": return analyticsPerformancePage
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
        id: wallpaperOptionsPage
        WallpaperOptionsPage {}
    }

    Component {
        id: wallpaperOptimizationPage
        WallpaperOptimizationPage {}
    }

    Component {
        id: wallpaperCachePage
        WallpaperCachePage {}
    }

    Component {
        id: wallpaperDirectoryPage
        WallpaperDirectoryPage {}
    }

    Component {
        id: islandStylePage
        IslandStylePage {}
    }

    Component {
        id: analyticsLifecyclePage
        LifecycleAnalyticsPage {}
    }

    Component {
        id: analyticsWallpaperPage
        WallpaperAnalyticsPage {}
    }

    Component {
        id: analyticsPerformancePage
        PerformanceAnalyticsPage {}
    }
}
