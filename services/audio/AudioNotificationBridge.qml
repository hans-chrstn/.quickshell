import QtQuick
import qs.services
import qs.services.notifications
import "AudioHotplugModel.js" as AudioHotplugModel

Item {
    id: root

    visible: false
    width: 0
    height: 0

    function displayName(stableKey, fallbackName) {
        const alias = AudioService.deviceAlias(String(stableKey || ""));
        return alias.length > 0 ? alias : String(fallbackName || "Audio device");
    }

    function severity(kind) {
        if (kind === "restored")
            return "success";
        if (kind === "available-again")
            return "info";
        return "warning";
    }

    function title(kind, role) {
        const label = role === "input" ? "Audio input" : "Audio output";
        if (kind === "disconnected")
            return label + " unavailable";
        if (kind === "restored")
            return label + " restored";
        if (kind === "available-again")
            return label + " reconnected";
        return label + " changed";
    }

    function present(transition) {
        const kind = String(transition?.kind || "");
        const role = String(transition?.role || "");
        if (!["fallback", "disconnected", "restored", "available-again"].includes(kind) || (role !== "output" && role !== "input"))
            return false;
        const fromName = displayName(transition.fromStableKey, transition.fromName);
        const toName = displayName(transition.toStableKey, transition.toName);
        const screenName = AudioPanelService.targetScreenName.length > 0 ? AudioPanelService.targetScreenName : ScreenService.resolve("");
        return NotificationService.notify({
            severity: severity(kind),
            title: title(kind, role),
            message: AudioHotplugModel.messageFor(kind, role, fromName, toName),
            screenName: screenName,
            dedupeKey: "audio-hotplug:" + role,
            source: "Sound"
        });
    }

    Connections {
        target: AudioService

        function onDeviceTransitionOccurred(transition) {
            root.present(transition);
        }
    }
}
