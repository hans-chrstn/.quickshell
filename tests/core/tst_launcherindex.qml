import QtQuick
import QtTest
import "../../services/launcher/LauncherIndex.js" as LauncherIndex

TestCase {
    name: "LauncherIndex"

    function test_catalogExcludesHiddenDuplicatesAndKeepsProvidedActions() {
        const openAction = {
            id: "new-window",
            name: "New Window",
            execute: function () {}
        };
        const entries = LauncherIndex.catalog([
            {
                id: "browser",
                name: "Browser",
                genericName: "Web Browser",
                actions: [openAction]
            },
            {
                id: "browser",
                name: "Duplicate"
            },
            {
                id: "secret",
                name: "Secret",
                noDisplay: true
            },
            {
                id: "terminal",
                name: "Terminal",
                actions: []
            }
        ]);
        compare(entries.length, 2);
        compare(entries[0].id, "browser");
        compare(entries[0].actions.length, 1);
        compare(entries[0].actions[0].id, "new-window");
        compare(entries[1].actions.length, 0);
    }

    function test_searchRanksNameBeforeMetadataAndBoundsResults() {
        const entries = LauncherIndex.catalog([
            {
                id: "browser",
                name: "Browser",
                genericName: "Web Browser"
            },
            {
                id: "web-tool",
                name: "Utility",
                comment: "Browse the web"
            },
            {
                id: "terminal",
                name: "Terminal",
                keywords: ["browser"]
            }
        ]);
        const results = LauncherIndex.search(entries, "browser", 2);
        compare(results.length, 2);
        compare(results[0].id, "browser");
        compare(results[1].id, "terminal");
        compare(LauncherIndex.search(entries, "zzzz", 80).length, 0);
    }

    function test_emptyQueryShowsAlphabeticalCatalog() {
        const entries = LauncherIndex.catalog([
            {
                id: "z",
                name: "Zeta"
            },
            {
                id: "a",
                name: "Alpha"
            }
        ]);
        const results = LauncherIndex.search(entries, "", 80);
        compare(results[0].title, "Alpha");
        compare(results[1].title, "Zeta");
    }
}
