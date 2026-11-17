import QtQuick
import QtTest
import "../../services/shell/SurfaceCoordination.js" as Coordination

TestCase {
    name: "SurfaceCoordination"

    function test_selectionIsPerOutputAndPerSurface() {
        const outputs = ["DP-1", "DP-3"];
        const first = Coordination.select({}, outputs, "DP-1", "island", "media");
        verify(first.accepted);
        const second = Coordination.select(first.state, outputs, "DP-1", "rail", "audio");
        const third = Coordination.select(second.state, outputs, "DP-3", "island", "launcher");
        compare(Coordination.routeFor(third.state, "DP-1", "island"), "media");
        compare(Coordination.routeFor(third.state, "DP-1", "rail"), "audio");
        compare(Coordination.routeFor(third.state, "DP-3", "island"), "launcher");
        compare(Coordination.routeFor(first.state, "DP-1", "rail"), "");
    }

    function test_unknownOutputAndSlotCannotOpenSurface() {
        const outputs = ["DP-1"];
        verify(!Coordination.select({}, outputs, "DP-3", "island", "media").accepted);
        verify(!Coordination.select({}, outputs, "DP-1", "lock", "media").accepted);
        compare(Coordination.routeFor({}, "DP-1", "lock"), "");
    }

    function test_disconnectedOutputIsPrunedWithoutChangingOtherOutput() {
        const routes = {
            "DP-1": {
                island: "media",
                rail: "audio"
            },
            "DP-3": {
                island: "launcher",
                rail: ""
            }
        };
        const kept = Coordination.reconcile(routes, ["DP-1"]);
        compare(Object.keys(kept).length, 1);
        compare(Coordination.routeFor(kept, "DP-1", "rail"), "audio");
        compare(Coordination.routeFor(routes, "DP-3", "island"), "launcher");
    }

    function test_closingLastRouteRemovesEmptyOutputRecord() {
        const opened = Coordination.select({}, ["DP-1"], "DP-1", "island", "media");
        const closed = Coordination.select(opened.state, ["DP-1"], "DP-1", "island", "");
        verify(closed.accepted);
        compare(Object.keys(closed.state).length, 0);
    }
}
