pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services.config
import qs.services.display

Singleton {
    id: root

    readonly property bool enabled: ConfigService.experimentalDpmsOnIdle
    readonly property bool idle: DisplayActivityService.idle
    readonly property string state: enabled ? (idle ? "off-requested" : "wake-requested") : "disabled"
    readonly property string error: ""

    function dispatch(action) {
        const testScreen = Quickshell.env("QS_DPMS_TEST_SCREEN") || "";
        const monitor = Quickshell.env("QS_TEST_MODE") === "1" && testScreen.length ? testScreen : "all";
        Hyprland.dispatch(`hl.dsp.dpms({monitor="${monitor}", action="${action}"})`);
    }

    function applyIdleState() {
        if (!root.enabled)
            return;
        Qt.callLater(() => root.dispatch(root.idle ? "off" : "on"));
    }

    Connections {
        target: DisplayActivityService
        enabled: root.enabled
        function onIdleChanged() {
            root.applyIdleState();
        }
    }

    function snapshot() {
        return {
            enabled: enabled,
            idle: idle,
            state: state,
            target: Quickshell.env("QS_TEST_MODE") === "1" ? Quickshell.env("QS_DPMS_TEST_SCREEN") || "all" : "all",
            backend: "hyprland-dispatch-lua"
        };
    }
}
