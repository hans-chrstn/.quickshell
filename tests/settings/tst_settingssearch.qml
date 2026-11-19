import QtQuick
import QtTest
import "../../services/settings/SettingsSearch.js" as Search

TestCase {
    name: "SettingsSearch"

    readonly property var categories: [
        {
            id: "personalization",
            title: "Personalization",
            subpages: [
                {
                    id: "wallpaper",
                    title: "Wallpaper",
                    desc: "Select background images"
                },
                {
                    id: "island_style",
                    title: "Island Style",
                    desc: "Customize dimensions and blur"
                }
            ],
            searchPages: [
                {
                    id: "wallpaper_cache",
                    title: "Wallpaper Cache",
                    desc: "Cached previews and cleanup",
                    parentId: "wallpaper",
                    parentTitle: "Wallpaper"
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
                    desc: "Inspect widget retention"
                },
                {
                    id: "analytics_performance",
                    title: "Performance",
                    desc: "Shell resources",
                    keywords: "cpu memory"
                }
            ]
        }
    ]

    function test_matchesFuzzyTitleAndShowsCategory() {
        const results = Search.search(categories, "lifcycl", 20);
        compare(results.length, 1);
        compare(results[0].id, "analytics_lifecycle");
        compare(results[0].categoryTitle, "Analytics");
    }

    function test_matchesAcrossFieldsAndRanksExactTitleFirst() {
        const wallpaper = Search.search(categories, "personal background", 20);
        compare(wallpaper.length, 1);
        compare(wallpaper[0].id, "wallpaper");
        const lifecycle = Search.search(categories, "lifecycle", 20);
        compare(lifecycle[0].id, "analytics_lifecycle");
    }

    function test_emptyUnknownAndLimit() {
        compare(Search.search(categories, "", 20).length, 0);
        compare(Search.search(categories, "zzzzzz", 20).length, 0);
        compare(Search.search(categories, "personalization", 1).length, 1);
    }

    function test_nestedPageHasBreadcrumbAndParent() {
        const results = Search.search(categories, "wal cache", 20);
        compare(results.length, 1);
        compare(results[0].id, "wallpaper_cache");
        compare(results[0].parentId, "wallpaper");
        compare(results[0].categoryTitle, "Personalization › Wallpaper");
    }

    function test_keywordFindsIndividualSetting() {
        const results = Search.search(categories, "cpu", 20);
        compare(results.length, 1);
        compare(results[0].id, "analytics_performance");
    }
}
