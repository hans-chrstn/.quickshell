pragma Singleton

import QtQuick
import Quickshell
import qs.services
import "IslandPresentationModel.js" as IslandPresentationModel

Singleton {
    id: root

    property var zenScreens: ({})
    property int revision: 0

    function availableScreenNames() {
        return Quickshell.screens.map(screen => String(screen?.name || "")).filter(name => name.length > 0);
    }

    function resolveScreenName(preferredName) {
        const requested = String(preferredName || "").trim();
        if (requested.length === 0)
            return ScreenService.resolve("");
        return availableScreenNames().includes(requested) ? requested : "";
    }

    function isZenEnabled(screenName) {
        return IslandPresentationModel.isZenEnabled(zenScreens, screenName);
    }

    function setZenEnabled(screenName, enabled) {
        const resolved = resolveScreenName(screenName);
        if (resolved.length === 0)
            return false;
        const result = IslandPresentationModel.setZenEnabled(zenScreens, resolved, enabled);
        if (!result.accepted)
            return false;
        if (result.changed) {
            zenScreens = result.state;
            revision += 1;
        }
        return true;
    }

    function toggleZen(screenName) {
        const resolved = resolveScreenName(screenName);
        if (resolved.length === 0)
            return false;
        return setZenEnabled(resolved, !isZenEnabled(resolved));
    }

    function synchronizeScreens() {
        const retained = IslandPresentationModel.retainAvailable(zenScreens, availableScreenNames());
        const previousNames = IslandPresentationModel.enabledScreenNames(zenScreens);
        const retainedNames = IslandPresentationModel.enabledScreenNames(retained);
        if (JSON.stringify(previousNames) === JSON.stringify(retainedNames))
            return;
        zenScreens = retained;
        revision += 1;
    }

    function snapshot() {
        return {
            mode: "per-screen-attention-suppression",
            persistent: false,
            revision: revision,
            zenScreens: IslandPresentationModel.enabledScreenNames(zenScreens)
        };
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            root.synchronizeScreens();
        }
    }
}
