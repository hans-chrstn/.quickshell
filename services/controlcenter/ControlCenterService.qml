pragma Singleton

import QtQuick
import Quickshell
import qs.services
import qs.services.audio
import qs.services.bluetooth
import qs.services.network
import qs.services.settings
import qs.services.shell

Singleton {
    id: root

    property bool opened: false
    property bool closing: false
    property bool switchingItem: false
    property string currentItem: ""
    property string targetScreenName: ""
    readonly property var items: [
        {
            id: "audio",
            glyph: "volumeHigh",
            name: "Audio",
            enabled: true,
            pageSource: Qt.resolvedUrl("../../controlcenter/ControlCenterAudioPage.qml"),
            restorationSource: "AudioPanelService and AudioService",
            activate: screenName => AudioPanelService.open(screenName),
            deactivate: () => AudioPanelService.close()
        },
        {
            id: "network",
            glyph: "ethernet",
            name: "Ethernet",
            enabled: NetworkService.backend !== "none" && NetworkService.wiredLinks.length > 0,
            pageSource: Qt.resolvedUrl("../../controlcenter/ControlCenterNetworkPage.qml"),
            restorationSource: "NetworkService"
        },
        {
            id: "bluetooth",
            glyph: "bluetooth",
            name: "Bluetooth",
            enabled: BluetoothService.available,
            pageSource: Qt.resolvedUrl("../../controlcenter/ControlCenterBluetoothPage.qml"),
            restorationSource: "BluetoothService and BlueZ"
        },
        {
            id: "settings",
            glyph: "settings",
            name: "Settings",
            enabled: true,
            pageSource: Qt.resolvedUrl("../../controlcenter/ControlCenterSettingsPage.qml"),
            restorationSource: "SettingsService and ConfigService",
            activate: screenName => SettingsService.open(screenName),
            deactivate: () => SettingsService.close()
        },
        {
            id: "lock",
            glyph: "lock",
            name: "Lock",
            enabled: false
        }
    ]
    readonly property var activeItem: items.find(item => item.id === currentItem) || null

    function openItem(itemId, preferredScreenName) {
        const item = items.find(record => record.id === itemId && record.enabled);
        const screenName = ScreenService.resolve(preferredScreenName || "");
        if (!item || !screenName)
            return false;
        const previous = activeItem;
        switchingItem = true;
        if (item.activate && item.activate(screenName) === false) {
            switchingItem = false;
            return false;
        }
        if (previous && previous.id !== item.id && previous.deactivate)
            previous.deactivate();
        currentItem = item.id;
        targetScreenName = screenName;
        closing = false;
        opened = true;
        switchingItem = false;
        TransientUiCoordinator.select(screenName, "control-center", item.id);
        return true;
    }

    function close() {
        if (!opened || closing)
            return false;
        switchingItem = true;
        if (activeItem?.deactivate)
            activeItem.deactivate();
        opened = false;
        closing = true;
        switchingItem = false;
        TransientUiCoordinator.select(targetScreenName, "control-center", "");
        return true;
    }

    function syncExternalItem(itemId, externalOpened, externalClosing, externalScreenName) {
        if (switchingItem)
            return;
        if (externalOpened) {
            currentItem = itemId;
            targetScreenName = externalScreenName;
            closing = false;
            opened = true;
            TransientUiCoordinator.select(targetScreenName, "control-center", itemId);
        } else if (currentItem === itemId && opened) {
            opened = false;
            closing = externalClosing;
            TransientUiCoordinator.select(targetScreenName, "control-center", "");
        } else if (!externalClosing && !opened && currentItem === itemId) {
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
            root.syncExternalItem("audio", AudioPanelService.opened, AudioPanelService.closing, AudioPanelService.targetScreenName);
        }
        function onClosingChanged() {
            root.syncExternalItem("audio", AudioPanelService.opened, AudioPanelService.closing, AudioPanelService.targetScreenName);
        }
        function onTargetScreenNameChanged() {
            root.syncExternalItem("audio", AudioPanelService.opened, AudioPanelService.closing, AudioPanelService.targetScreenName);
        }
    }

    Connections {
        target: SettingsService
        function onOpenedChanged() {
            root.syncExternalItem("settings", SettingsService.opened, SettingsService.closing, SettingsService.targetScreenName);
        }
        function onClosingChanged() {
            root.syncExternalItem("settings", SettingsService.opened, SettingsService.closing, SettingsService.targetScreenName);
        }
        function onTargetScreenNameChanged() {
            root.syncExternalItem("settings", SettingsService.opened, SettingsService.closing, SettingsService.targetScreenName);
        }
    }

    Component.onCompleted: {
        syncExternalItem("audio", AudioPanelService.opened, AudioPanelService.closing, AudioPanelService.targetScreenName);
        syncExternalItem("settings", SettingsService.opened, SettingsService.closing, SettingsService.targetScreenName);
    }
}
