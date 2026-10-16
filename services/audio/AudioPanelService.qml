pragma Singleton

import QtQuick
import Quickshell
import qs.core
import qs.services

Singleton {
    id: root

    property bool opened: false
    property bool closing: false
    property string targetScreenName: ""
    property string currentPage: "levels"
    readonly property var pages: ["levels", "output", "input"]

    function syncInventoryDemand() {
        AudioService.setInventoryConsumer("audio-panel.devices", (opened || closing) && (currentPage === "output" || currentPage === "input"));
    }

    onOpenedChanged: syncInventoryDemand()
    onClosingChanged: syncInventoryDemand()
    onCurrentPageChanged: syncInventoryDemand()

    function open(preferredScreenName) {
        closeTimer.stop();
        const resolvedScreen = ScreenService.resolve(preferredScreenName || "");
        if (resolvedScreen.length === 0)
            return false;
        targetScreenName = resolvedScreen;
        opened = true;
        closing = false;
        return true;
    }

    function close() {
        if (!opened || closing)
            return false;
        closing = true;
        opened = false;
        closeTimer.restart();
        return true;
    }

    function selectPage(pageId) {
        const requested = String(pageId || "").trim();
        if (!pages.includes(requested) || requested === currentPage)
            return false;
        currentPage = requested;
        return true;
    }

    function toggle(preferredScreenName) {
        return opened ? close() : open(preferredScreenName);
    }

    function snapshot() {
        return {
            opened: opened,
            closing: closing,
            targetScreenName: targetScreenName,
            currentPage: currentPage
        };
    }

    Timer {
        id: closeTimer
        interval: Design.moduleHandoffDuration
        onTriggered: {
            root.closing = false;
            root.currentPage = "levels";
            root.targetScreenName = "";
        }
    }
}
