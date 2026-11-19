pragma Singleton

import QtQuick
import Quickshell
import qs.core
import qs.services
import qs.services.audio
import "OsdModel.js" as Model

Singleton {
    id: root

    property var current: null
    property bool visible: false
    property bool closing: false
    property int presentationCount: 0
    readonly property bool active: visible || closing
    readonly property string targetScreenName: current?.screenName || ""

    function present(kind, value, muted, preferredScreenName) {
        const screenName = ScreenService.resolve(preferredScreenName || "");
        const candidate = Model.normalized(kind, value, muted, screenName);
        if (!candidate || !screenName || kind === "brightness" && !BrightnessService.available)
            return false;
        closeTimer.stop();
        current = candidate;
        closing = false;
        visible = true;
        presentationCount += 1;
        expiryTimer.restart();
        return true;
    }

    function preview(kind, value, muted, screenName) {
        const candidate = Model.normalized(kind, value, muted, ScreenService.resolve(screenName || ""));
        if (!candidate || !candidate.screenName)
            return false;
        closeTimer.stop();
        current = candidate;
        closing = false;
        visible = true;
        presentationCount += 1;
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

    function snapshot() {
        return {
            active: active,
            visible: visible,
            closing: closing,
            targetScreenName: targetScreenName,
            presentationCount: presentationCount,
            brightnessAvailable: BrightnessService.available,
            current: current
        };
    }

    Connections {
        target: AudioService
        function onSemanticChange(change) {
            if (AudioPanelService.opened || AudioPanelService.closing || change?.changedFields?.length === 0)
                return;
            if (change.role === "output")
                root.present("volume", change.volume, change.muted, "");
            else if (change.role === "input" && change.changedFields.includes("muted"))
                root.present("microphone", change.volume, change.muted, "");
        }
    }

    Connections {
        target: BrightnessService
        function onChanged(level) {
            root.present("brightness", level, false, "");
        }
    }

    Timer {
        id: expiryTimer
        interval: Design.osdHoldDuration
        onTriggered: root.dismiss()
    }

    Timer {
        id: closeTimer
        interval: Design.osdRetireDuration
        onTriggered: {
            if (!root.visible) {
                root.closing = false;
                root.current = null;
            }
        }
    }
}
