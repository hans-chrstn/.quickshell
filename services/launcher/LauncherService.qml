pragma Singleton

import QtQuick
import Quickshell
import qs.core
import qs.services.launcher
import qs.services.shell
import qs.services

Singleton {
    id: root

    property bool opened: false
    property bool closing: false
    property string targetScreenName: ""
    property string query: ""
    property int selectedIndex: 0

    readonly property var providers: [DesktopAppProvider]
    readonly property var results: {
        if (!opened && !closing)
            return [];

        const merged = [];
        for (let i = 0; i < providers.length; ++i) {
            const provider = providers[i];
            if (!provider.enabled)
                continue;
            const contribution = provider.search(query);
            for (let j = 0; j < contribution.length; ++j)
                merged.push(contribution[j]);
        }

        merged.sort(function (a, b) {
            if (a.score !== b.score)
                return b.score - a.score;
            if (a.providerId !== b.providerId)
                return a.providerId.localeCompare(b.providerId);
            return a.title.localeCompare(b.title);
        });
        return merged;
    }

    onQueryChanged: selectedIndex = 0
    onResultsChanged: {
        if (results.length === 0)
            selectedIndex = -1;
        else
            selectedIndex = Math.max(0, Math.min(selectedIndex, results.length - 1));
    }

    function open(initialQuery, preferredScreenName) {
        closeTimer.stop();
        closing = false;
        targetScreenName = ScreenService.resolve(preferredScreenName || "");
        query = initialQuery || "";
        selectedIndex = 0;
        opened = true;
    }

    function close() {
        if (!opened || closing)
            return;
        closing = true;
        opened = false;
        closeTimer.restart();
    }

    function toggle() {
        opened ? close() : open("");
    }

    function moveSelection(delta) {
        if (results.length === 0) {
            selectedIndex = -1;
            return;
        }
        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + delta));
    }

    function executeSelected() {
        if (selectedIndex < 0 || selectedIndex >= results.length)
            return false;
        return executeResult(results[selectedIndex].id);
    }

    function executeResult(id) {
        const result = results.find(entry => entry.id === id);
        if (!result)
            return false;
        for (let i = 0; i < providers.length; ++i) {
            if (providers[i].providerId === result.providerId) {
                providers[i].execute(result);
                close();
                TransientUiCoordinator.closeAll("app-launched");
                return true;
            }
        }
        return false;
    }

    function executeAction(id, actionId) {
        const result = results.find(entry => entry.id === id);
        if (!result || !actionId)
            return false;
        for (const provider of providers) {
            if (provider.providerId === result.providerId && provider.executeAction?.(result, actionId)) {
                close();
                TransientUiCoordinator.closeAll("app-action-launched");
                return true;
            }
        }
        return false;
    }

    function snapshot() {
        return {
            opened: opened,
            query: query,
            targetScreenName: targetScreenName,
            selectedIndex: selectedIndex,
            resultCount: results.length,
            catalogSize: DesktopAppProvider.catalogSize,
            selected: selectedIndex >= 0 && selectedIndex < results.length ? {
                id: results[selectedIndex].id,
                title: results[selectedIndex].title,
                actions: results[selectedIndex].actions.map(action => ({
                            id: action.id,
                            name: action.name
                        }))
            } : null
        };
    }

    Timer {
        id: closeTimer
        interval: Design.moduleHandoffDuration
        onTriggered: {
            root.closing = false;
            root.query = "";
            root.selectedIndex = 0;
        }
    }
}
