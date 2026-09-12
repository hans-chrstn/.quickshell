import QtQuick
import qs.components
import qs.components.lifecycle
import qs.core
import qs.services.settings

Item {
    id: root

    property QtObject context: null
    readonly property string screenName: context?.screenName ?? ""
    readonly property url currentPageSource: pageSource(
        SettingsService.currentPage)
    focus: true
    enabled: SettingsService.opened

    function pageSource(pageId) {
        switch (pageId) {
        case "wallpaper": return Qt.resolvedUrl("WallpaperSettingsPage.qml")
        case "wallpaper_options": return Qt.resolvedUrl("WallpaperOptionsPage.qml")
        case "wallpaper_optimization": return Qt.resolvedUrl("WallpaperOptimizationPage.qml")
        case "wallpaper_cache": return Qt.resolvedUrl("WallpaperCachePage.qml")
        case "wallpaper_directory": return Qt.resolvedUrl("WallpaperDirectoryPage.qml")
        case "island_style": return Qt.resolvedUrl("IslandStylePage.qml")
        case "motion": return Qt.resolvedUrl("MotionSettingsPage.qml")
        case "behavior": return Qt.resolvedUrl("BehaviorSettingsPage.qml")
        case "analytics_lifecycle": return Qt.resolvedUrl("LifecycleAnalyticsPage.qml")
        case "analytics_wallpaper": return Qt.resolvedUrl("WallpaperAnalyticsPage.qml")
        case "analytics_performance": return Qt.resolvedUrl("PerformanceAnalyticsPage.qml")
        case "developer_advanced": return Qt.resolvedUrl("AdvancedDeveloperPage.qml")
        case "developer_lifecycle": return Qt.resolvedUrl("LifecycleDeveloperPage.qml")
        default: return Qt.resolvedUrl("SettingsSubpageMenu.qml")
        }
    }

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
        width: 144
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
        source: root.currentPageSource
    }
}
