import QtQuick
import QtTest
import "../../island/TopIslandState.js" as IslandState

TestCase {
    name: "TopIslandState"

    function test_wakeAndPointerPaths() {
        const compact = IslandState.reduce({}, {
            kind: "wake"
        });
        compare(compact.phase, "compact");
        compare(IslandState.reduce(compact, {
            kind: "left"
        }).phase, "media");
        compare(IslandState.reduce(compact, {
            kind: "right"
        }).phase, "notifications");
        compare(IslandState.reduce(compact, {
            kind: "type"
        }).phase, "launcher");
    }

    function test_rightClickExpandsOnlyCurrentRoute() {
        const media = IslandState.reduce({
            phase: "compact"
        }, {
            kind: "left"
        });
        const expanded = IslandState.reduce(media, {
            kind: "right"
        });
        compare(expanded.phase, "media");
        verify(expanded.expanded);
        const compact = IslandState.reduce(expanded, {
            kind: "open-route",
            phase: "compact",
            expanded: true
        });
        compare(compact.phase, "compact");
        verify(!compact.expanded);
        verify(!IslandState.reduce(expanded, {
            kind: "right"
        }).expanded);
    }

    function test_ipcMediaIntentSelectsRequestedSize() {
        const normal = IslandState.reduce({
            phase: "hidden"
        }, {
            kind: "open-route",
            phase: "media",
            expanded: false
        });
        compare(normal.phase, "media");
        verify(!normal.expanded);
        const expanded = IslandState.reduce({
            phase: "launcher"
        }, {
            kind: "open-route",
            phase: "media",
            expanded: true
        });
        compare(expanded.phase, "media");
        verify(expanded.expanded);
        compare(IslandState.reduce(expanded, {
            kind: "open-route",
            phase: "settings"
        }).phase, "media");
    }

    function test_escapeUnwindsSizeRouteAndVisibility() {
        const expanded = {
            phase: "notifications",
            expanded: true
        };
        const normal = IslandState.reduce(expanded, {
            kind: "escape"
        });
        compare(normal.phase, "notifications");
        verify(!normal.expanded);
        const compact = IslandState.reduce(normal, {
            kind: "escape"
        });
        compare(compact.phase, "compact");
        compare(IslandState.reduce(compact, {
            kind: "escape"
        }).phase, "hidden");
    }

    function test_invalidStateAndOutsideFailClosed() {
        compare(IslandState.normalize({
            phase: "settings",
            expanded: true
        }).phase, "hidden");
        compare(IslandState.reduce({
            phase: "launcher",
            expanded: true
        }, {
            kind: "outside"
        }).phase, "hidden");
    }

    function test_typingOnlyOpensLauncherFromCompact() {
        const media = {
            phase: "media",
            expanded: false
        };
        const notifications = {
            phase: "notifications",
            expanded: true
        };
        compare(IslandState.reduce(media, {
            kind: "type"
        }).phase, "media");
        compare(IslandState.reduce(notifications, {
            kind: "type"
        }).phase, "notifications");
        compare(IslandState.reduce({
            phase: "compact"
        }, {
            kind: "type"
        }).phase, "launcher");
        compare(IslandState.reduce(media, {
            kind: "open-launcher"
        }).phase, "launcher");
    }

    function test_closingLauncherReturnsToCompact() {
        const closed = IslandState.reduce({
            phase: "launcher",
            expanded: true
        }, {
            kind: "launcher-closed"
        });
        compare(closed.phase, "compact");
        verify(!closed.expanded);
        compare(IslandState.reduce({
            phase: "media"
        }, {
            kind: "launcher-closed"
        }).phase, "media");
    }
}
