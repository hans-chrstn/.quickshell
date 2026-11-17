pragma Singleton

import QtQuick
import Quickshell
import qs.core
import "LauncherIndex.js" as LauncherIndex

LauncherProvider {
    id: root

    providerId: "desktop-apps"

    readonly property var applications: DesktopEntries.applications.values
    readonly property var indexedApps: LauncherIndex.catalog(applications)
    readonly property int catalogSize: indexedApps.length

    function search(query) {
        if (!enabled)
            return [];

        return LauncherIndex.search(indexedApps, query, 80).map(entry => Object.assign({}, entry, {
                providerId: providerId,
                kind: "desktop-app"
            }));
    }

    function execute(result) {
        if (result?.app)
            result.app.execute();
    }

    function executeAction(result, actionId) {
        for (const action of result?.actions || []) {
            if (action.id === actionId && action.action) {
                action.action.execute();
                return true;
            }
        }
        return false;
    }
}
