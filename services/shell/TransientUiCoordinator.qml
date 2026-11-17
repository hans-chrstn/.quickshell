pragma Singleton

import QtQuick
import Quickshell
import "SurfaceCoordination.js" as SurfaceCoordination

Singleton {
    id: root

    property var routes: ({})

    signal closeAllRequested(string reason)

    function screenNames() {
        return Quickshell.screens.map(screen => String(screen?.name || "")).filter(name => name.length > 0);
    }

    function select(screenName, slot, route) {
        const result = SurfaceCoordination.select(routes, screenNames(), screenName, slot, route);
        if (result.accepted)
            routes = result.state;
        return result.accepted;
    }

    function routeFor(screenName, slot) {
        return SurfaceCoordination.routeFor(routes, screenName, slot);
    }

    function closeAll(reason) {
        routes = ({});
        closeAllRequested(String(reason || ""));
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            root.routes = SurfaceCoordination.reconcile(root.routes, root.screenNames());
        }
    }
}
