pragma Singleton

import QtQuick
import Quickshell
import qs.services
import qs.services.config
import "SettingsSearch.js" as SettingsSearch

Singleton {
    id: root

    property bool opened: false
    property bool closing: false
    property string targetScreenName: ""
    property int selectedCategory: 0
    property string searchQuery: ""
    property string wallpaperTarget: "desktop"
    property string wallpaperScreenName: ""
    onSelectedCategoryChanged: if (opened)
        clearPages()
    property var pageStack: []
    readonly property string currentPage: pageStack.length > 0 ? String(pageStack[pageStack.length - 1]) : ""
    readonly property var searchResults: SettingsSearch.search(categories, searchQuery, 20)

    readonly property int revealDuration: ConfigService.revealDuration
    readonly property int resizeDuration: ConfigService.resizeDuration
    readonly property int contentRevealDuration: ConfigService.contentRevealDuration
    readonly property int attentionExpandDelay: ConfigService.attentionExpandDelay
    readonly property int moduleCloseDuration: ConfigService.moduleCloseDuration
    readonly property int moduleHandoffDuration: Math.max(moduleCloseDuration, resizeDuration)
    readonly property int expandDelay: ConfigService.expandDelay
    readonly property int hideDelay: ConfigService.hideDelay
    readonly property int islandWing: ConfigService.islandWing
    readonly property int islandCollapsedWidth: ConfigService.islandCollapsedWidth
    readonly property int islandWidthPercent: ConfigService.islandWidthPercent
    readonly property int islandHeightPercent: ConfigService.islandHeightPercent
    readonly property int islandBodyRadius: ConfigService.islandBodyRadius
    readonly property int topIslandCompactWidth: ConfigService.topIslandCompactWidth
    readonly property int topIslandExpandedScale: ConfigService.topIslandExpandedScale
    readonly property int topIslandCornerRadius: ConfigService.topIslandCornerRadius
    readonly property int topIslandEnterFadeDuration: ConfigService.topIslandEnterFadeDuration
    readonly property int topIslandExitFadeDuration: ConfigService.topIslandExitFadeDuration
    readonly property int topIslandContentFadeDuration: ConfigService.topIslandContentFadeDuration
    readonly property int topIslandHoverLeaveDelay: ConfigService.topIslandHoverLeaveDelay
    readonly property bool enableBlur: ConfigService.enableBlur
    readonly property bool adaptiveLifecycleEnabled: ConfigService.adaptiveLifecycleEnabled
    readonly property int lifecycleInactiveBudgetUnits: ConfigService.lifecycleInactiveBudgetUnits

    readonly property var categories: [
        {
            id: "personalization",
            title: "Personalization",
            subpages: [
                {
                    id: "wallpaper",
                    title: "Wallpaper",
                    desc: "Desktop and lock screen",
                    keywords: "background images video displays assign studio editor"
                },
                {
                    id: "island_style",
                    title: "Island Style",
                    desc: "Size and glass",
                    keywords: "compact width expanded scale corner radius compositor blur"
                }
            ],
            searchPages: [
                {
                    id: "wallpaper_options",
                    title: "Wallpaper Options",
                    desc: "Playback and transitions",
                    keywords: "pause animation idle transitions duration reduce motion coverage battery",
                    parentId: "wallpaper",
                    parentTitle: "Wallpaper"
                },
                {
                    id: "wallpaper_optimization",
                    title: "Wallpaper Optimization",
                    desc: "Scale, frame rate, bitrate",
                    keywords: "scale frame rate bitrate transcoding",
                    parentId: "wallpaper",
                    parentTitle: "Wallpaper"
                },
                {
                    id: "wallpaper_cache",
                    title: "Wallpaper Cache",
                    desc: "Storage and cleanup",
                    keywords: "automatic bounded cleanup refresh clean planned clear all",
                    parentId: "wallpaper",
                    parentTitle: "Wallpaper"
                },
                {
                    id: "wallpaper_directory",
                    title: "Wallpaper Library",
                    desc: "Image folder",
                    keywords: "directory browse path",
                    parentId: "wallpaper",
                    parentTitle: "Wallpaper"
                },
                {
                    id: "wallpaper_file",
                    title: "Wallpaper File",
                    desc: "Select one image",
                    keywords: "browse image file preview lock desktop",
                    parentId: "wallpaper",
                    parentTitle: "Wallpaper"
                },
                {
                    id: "wallpaper_adjust",
                    title: "Wallpaper Placement",
                    desc: "Frame and rotate",
                    keywords: "image placement crop pan zoom rotate",
                    parentId: "wallpaper",
                    parentTitle: "Wallpaper"
                }
            ]
        },
        {
            id: "interaction",
            title: "Interaction",
            subpages: [
                {
                    id: "motion",
                    title: "Motion",
                    desc: "Entrance, exit, content",
                    keywords: "island enter exit content reveal fade timing"
                },
                {
                    id: "behavior",
                    title: "Behavior",
                    desc: "Hide delay and quiet mode",
                    keywords: "auto hide zen mode notifications privacy"
                }
            ]
        },
        {
            id: "analytics",
            title: "Analytics",
            subpages: [
                {
                    id: "analytics_lifecycle",
                    title: "Lifecycle",
                    desc: "Loaded and idle views",
                    keywords: "resource leases suspended active memory"
                },
                {
                    id: "analytics_wallpaper",
                    title: "Wallpaper",
                    desc: "Rendering and cache use",
                    keywords: "decode media cache transition"
                },
                {
                    id: "analytics_performance",
                    title: "Performance",
                    desc: "Memory and CPU",
                    keywords: "cpu memory rss pss threads uptime"
                }
            ]
        },
        {
            id: "developer",
            title: "Developer Options",
            subpages: [
                {
                    id: "developer_advanced",
                    title: "Advanced",
                    desc: "Power and resource controls",
                    keywords: "adaptive lifecycle dpms idle display power"
                }
            ],
            searchPages: [
                {
                    id: "developer_lifecycle",
                    title: "Lifecycle Controls",
                    desc: "Idle view budget",
                    keywords: "inactive budget priority memory",
                    parentId: "developer_advanced",
                    parentTitle: "Advanced"
                }
            ]
        }
    ]

    function open(preferredScreenName) {
        closeTimer.stop();
        closing = false;
        targetScreenName = ScreenService.resolve(preferredScreenName || "");
        selectedCategory = 0;
        searchQuery = "";
        clearPages();
        opened = true;
    }

    function openCategory(categoryId, preferredScreenName) {
        const requested = String(categoryId || "").trim();

        for (let index = 0; index < categories.length; ++index) {
            if (categories[index].id === requested) {
                open(preferredScreenName);
                selectedCategory = index;
                clearPages();
                return true;
            }
        }

        for (let index = 0; index < categories.length; ++index) {
            const cat = categories[index];
            for (let subIndex = 0; subIndex < cat.subpages.length; ++subIndex) {
                if (cat.subpages[subIndex].id === requested) {
                    open(preferredScreenName);
                    selectedCategory = index;
                    pageStack = [requested];
                    return true;
                }
            }
            for (const page of cat.searchPages || []) {
                if (page.id === requested) {
                    open(preferredScreenName);
                    selectedCategory = index;
                    pageStack = page.parentId ? [page.parentId, requested] : [requested];
                    return true;
                }
            }
        }
        return false;
    }

    function close() {
        if (!opened || closing)
            return;
        closing = true;
        opened = false;
        closeTimer.restart();
    }

    function toggle(preferredScreenName) {
        opened ? close() : open(preferredScreenName);
    }

    function setSetting(key, value) {
        return ConfigService.setSetting(key, value);
    }

    function snapshot() {
        return {
            opened: opened,
            closing: closing,
            targetScreenName: targetScreenName,
            selectedCategory: selectedCategory,
            searchQuery: searchQuery,
            searchResultCount: searchResults.length,
            currentPage: currentPage,
            pageStack: pageStack.slice()
        };
    }

    function clearPages() {
        pageStack = [];
    }

    function openSearchResult(pageId) {
        const result = searchResults.find(entry => entry.id === pageId);
        if (!result)
            return false;
        const index = categories.findIndex(category => category.id === result.categoryId);
        if (index < 0)
            return false;
        selectedCategory = index;
        pageStack = result.parentId ? [result.parentId] : [];
        searchQuery = "";
        return openPage(pageId);
    }

    function openPage(pageId) {
        const requested = String(pageId || "").trim();
        if (requested.length === 0 || requested === currentPage)
            return false;
        pageStack = pageStack.concat([requested]);
        return true;
    }

    function back() {
        if (pageStack.length === 0)
            return false;
        pageStack = pageStack.slice(0, pageStack.length - 1);
        return true;
    }

    function openWallpaperDirectoryPicker(preferredScreenName) {
        openCategory("wallpaper", preferredScreenName);
        openPage("wallpaper_directory");
    }

    function openWallpaperOptions(preferredScreenName) {
        openCategory("wallpaper", preferredScreenName);
        openPage("wallpaper_options");
    }

    function resetMotion() {
        ConfigService.setSettings({
            topIslandEnterFadeDuration: 310,
            topIslandExitFadeDuration: 480,
            topIslandContentFadeDuration: 210
        });
    }

    function resetBehavior() {
        ConfigService.setSettings({
            topIslandHoverLeaveDelay: 650
        });
    }

    function resetStyle() {
        ConfigService.setSettings({
            topIslandCompactWidth: 320,
            topIslandExpandedScale: 100,
            topIslandCornerRadius: 27,
            enableBlur: true
        });
    }

    function resetLifecycleSettings() {
        ConfigService.setSettings({
            adaptiveLifecycleEnabled: true,
            lifecycleInactiveBudgetUnits: 100
        });
    }

    Timer {
        id: closeTimer
        interval: root.moduleHandoffDuration
        onTriggered: {
            root.closing = false;
            root.clearPages();
        }
    }
}
