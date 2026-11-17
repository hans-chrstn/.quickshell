pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var states: ({})

    signal routeRequested(string screenName, string route, bool expanded)
    signal hideRequested(string screenName)

    function resolve(screenName) {
        return IslandPresentationService.resolveScreenName(screenName);
    }

    function openRoute(screenName, route, expanded) {
        const resolved = resolve(screenName);
        const requested = String(route || "").trim();
        if (resolved.length === 0 || !["compact", "media", "notifications", "launcher"].includes(requested))
            return false;
        routeRequested(resolved, requested, expanded === true);
        return true;
    }

    function openMedia(screenName, expanded) {
        return openRoute(screenName, "media", expanded);
    }

    function hide(screenName) {
        const resolved = resolve(screenName);
        if (resolved.length === 0)
            return false;
        hideRequested(resolved);
        return true;
    }

    function report(screenName, state) {
        const name = String(screenName || "").trim();
        if (name.length === 0)
            return;
        const next = Object.assign({}, states);
        next[name] = {
            phase: state?.phase || "hidden",
            expanded: state?.expanded === true
        };
        states = next;
    }

    function forget(screenName) {
        const next = Object.assign({}, states);
        delete next[String(screenName || "")];
        states = next;
    }

    function snapshot() {
        return {
            screens: states
        };
    }
}
