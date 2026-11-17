pragma Singleton

import QtQuick
import Quickshell
import qs.services
import qs.services.audio
import qs.services.shell

Singleton {
    id: root

    property bool opened: false
    property bool closing: false
    property string currentItem: ""
    property string targetScreenName: ""
    readonly property var items: [
        {
            id: "audio",
            glyph: "volumeHigh",
            name: "Audio",
            enabled: true
        },
        {
            id: "network",
            glyph: "wifi",
            name: "Network",
            enabled: false
        },
        {
            id: "bluetooth",
            glyph: "bluetooth",
            name: "Bluetooth",
            enabled: false
        },
        {
            id: "settings",
            glyph: "settings",
            name: "Settings",
            enabled: false
        },
        {
            id: "lock",
            glyph: "lock",
            name: "Lock",
            enabled: false
        }
    ]

    function openItem(itemId, preferredScreenName) {
        const item = items.find(record => record.id === itemId && record.enabled);
        const screenName = ScreenService.resolve(preferredScreenName || "");
        if (!item || !screenName)
            return false;
        if (item.id === "audio" && !AudioPanelService.open(screenName))
            return false;
        currentItem = item.id;
        targetScreenName = screenName;
        closing = false;
        opened = true;
        TransientUiCoordinator.select(screenName, "control-center", item.id);
        return true;
    }

    function close() {
        if (!opened || closing)
            return false;
        if (currentItem === "audio")
            AudioPanelService.close();
        opened = false;
        closing = true;
        TransientUiCoordinator.select(targetScreenName, "control-center", "");
        return true;
    }

    function syncAudio() {
        if (AudioPanelService.opened) {
            currentItem = "audio";
            targetScreenName = AudioPanelService.targetScreenName;
            closing = false;
            opened = true;
            TransientUiCoordinator.select(targetScreenName, "control-center", "audio");
        } else if (currentItem === "audio" && opened) {
            opened = false;
            closing = AudioPanelService.closing;
            TransientUiCoordinator.select(targetScreenName, "control-center", "");
        } else if (!AudioPanelService.closing && !opened && currentItem === "audio") {
            currentItem = "";
            targetScreenName = "";
            closing = false;
        }
    }

    function snapshot() {
        return {
            opened: opened,
            closing: closing,
            currentItem: currentItem,
            targetScreenName: targetScreenName,
            availableItems: items.filter(item => item.enabled).map(item => item.id)
        };
    }

    Connections {
        target: AudioPanelService
        function onOpenedChanged() {
            root.syncAudio();
        }
        function onClosingChanged() {
            root.syncAudio();
        }
        function onTargetScreenNameChanged() {
            root.syncAudio();
        }
    }

    Component.onCompleted: syncAudio()
}
