pragma Singleton

import QtQuick
import Quickshell
import qs.core
import qs.services
import "AudioPresentationModel.js" as AudioPresentationModel

Singleton {
    id: root

    readonly property int presentationDurationMs: AudioPresentationModel.defaultDurationMs
    property var current: null
    property bool visible: false
    property bool closing: false
    property int presentationCount: 0
    readonly property bool active: visible || closing
    readonly property string targetScreenName: String(current?.screenName || "")

    function present(change) {
        if (AudioPanelService.opened || AudioPanelService.closing)
            return false;
        const target = ScreenService.resolve("");
        const normalized = AudioPresentationModel.normalizedChange(change, target, Date.now(), presentationDurationMs);
        if (!normalized || normalized.screenName.length === 0)
            return false;
        closeTimer.stop();
        current = normalized;
        closing = false;
        visible = true;
        presentationCount += 1;
        expiryTimer.interval = normalized.durationMs;
        expiryTimer.restart();
        return true;
    }

    function dismiss() {
        if (!visible)
            return false;
        expiryTimer.stop();
        visible = false;
        closing = true;
        closeTimer.restart();
        return true;
    }

    function finishClose() {
        if (visible)
            return;
        closing = false;
        current = null;
    }

    function snapshot() {
        return {
            active: active,
            visible: visible,
            closing: closing,
            targetScreenName: targetScreenName,
            presentationCount: presentationCount,
            durationMs: presentationDurationMs,
            current: current ? Object.assign({}, current) : null
        };
    }

    Connections {
        target: AudioService

        function onSemanticChange(change) {
            root.present(change);
        }
    }

    Timer {
        id: expiryTimer
        onTriggered: root.dismiss()
    }

    Timer {
        id: closeTimer
        interval: Design.moduleHandoffDuration
        onTriggered: root.finishClose()
    }
}
