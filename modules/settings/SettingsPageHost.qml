import QtQuick
import qs.components.lifecycle
import qs.services.settings

Item {
    id: root

    required property string screenName
    property bool pageActive: true
    readonly property string pageId: SettingsService.currentPage

    function pageSource(pageId) {
        switch (pageId) {
        case "wallpaper":
            return Qt.resolvedUrl("WallpaperSettingsPage.qml");
        case "wallpaper_options":
            return Qt.resolvedUrl("WallpaperOptionsPage.qml");
        case "wallpaper_optimization":
            return Qt.resolvedUrl("WallpaperOptimizationPage.qml");
        case "wallpaper_cache":
            return Qt.resolvedUrl("WallpaperCachePage.qml");
        case "wallpaper_directory":
            return Qt.resolvedUrl("WallpaperDirectoryPage.qml");
        case "wallpaper_file":
            return Qt.resolvedUrl("WallpaperFilePage.qml");
        case "wallpaper_adjust":
            return Qt.resolvedUrl("WallpaperPlacementPage.qml");
        case "island_style":
            return Qt.resolvedUrl("IslandStylePage.qml");
        case "motion":
            return Qt.resolvedUrl("MotionSettingsPage.qml");
        case "behavior":
            return Qt.resolvedUrl("BehaviorSettingsPage.qml");
        case "analytics_lifecycle":
            return Qt.resolvedUrl("LifecycleAnalyticsPage.qml");
        case "analytics_wallpaper":
            return Qt.resolvedUrl("WallpaperAnalyticsPage.qml");
        case "analytics_performance":
            return Qt.resolvedUrl("PerformanceAnalyticsPage.qml");
        case "developer_advanced":
            return Qt.resolvedUrl("AdvancedDeveloperPage.qml");
        case "developer_lifecycle":
            return Qt.resolvedUrl("LifecycleDeveloperPage.qml");
        default:
            return Qt.resolvedUrl("SettingsSubpageMenu.qml");
        }
    }

    LifecycleLoader {
        anchors.fill: parent
        resourceId: "settings.page." + root.screenName + "." + (root.pageId || "category-menu")
        owner: "settings." + root.screenName
        restorationSource: "SettingsService route and ConfigService"
        classification: "active-only"
        registrationEnabled: root.screenName.length > 0
        requestedActive: root.pageActive
        retentionReason: root.pageActive ? "selected-route" : ""
        evictionReason: root.pageActive ? "" : "route-hidden"
        source: root.pageSource(root.pageId)
    }
}
