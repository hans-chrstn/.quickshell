pragma Singleton

import QtQuick
import Quickshell
import qs.components.lifecycle
import "../../core/JsonCopy.js" as JsonCopy

Singleton {
    id: root

    property var consumerScreens: ({})
    readonly property var poweredScreens: observer.item?.screens || ({})
    readonly property bool available: observer.item?.available === true
    readonly property string error: observer.status === Loader.Error ? "Display-power provider failed to load" : observer.item?.error || ""
    readonly property int consumers: {
        let total = 0;
        for (const name in consumerScreens)
            total += Number(consumerScreens[name]) || 0;
        return total;
    }
    readonly property bool observing: consumers > 0

    function acquire(screenName) {
        const name = String(screenName || "").trim();
        if (!name.length)
            return;
        const updated = Object.assign({}, consumerScreens);
        updated[name] = (Number(updated[name]) || 0) + 1;
        consumerScreens = updated;
    }

    function release(screenName) {
        const name = String(screenName || "").trim();
        const updated = Object.assign({}, consumerScreens);
        const count = Math.max(0, (Number(updated[name]) || 0) - 1);
        if (count)
            updated[name] = count;
        else
            delete updated[name];
        consumerScreens = updated;
    }

    function powered(screenName) {
        return poweredScreens[String(screenName || "")] === true;
    }

    function known(screenName) {
        return poweredScreens[String(screenName || "")] !== undefined;
    }

    LifecycleLoader {
        id: observer
        resourceId: "display.power-observer"
        owner: "wallpaper-monitor-power-service"
        restorationSource: "Wayland initial output-power events"
        classification: "active-only"
        requestedActive: root.observing
        retentionReason: requestedActive ? "display-power-consumers" : ""
        evictionReason: requestedActive ? "" : "no-display-power-consumers"
        source: Qt.resolvedUrl("../display/DisplayPowerProvider.qml")
    }

    function snapshot() {
        return {
            consumers: consumers,
            observing: observing,
            available: available,
            intervalMs: 0,
            backend: "wlr-output-power-management-v1",
            screens: JsonCopy.value(poweredScreens),
            error: error
        };
    }
}
