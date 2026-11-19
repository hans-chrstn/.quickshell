pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "BluetoothModel.js" as Model

Singleton {
    id: root

    property var consumers: ({})
    property bool scanOwned: false
    property string selectedAddress: ""
    property string error: ""
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool scanning: adapter?.discovering ?? false
    readonly property var devices: Model.sortDevices(adapter?.devices?.values ?? [])
    readonly property var selectedDevice: devices.find(device => device.address === selectedAddress) || null
    readonly property int consumerCount: Object.keys(consumers).length

    function setConsumer(id, active) {
        const key = String(id || "");
        if (!key)
            return;
        const next = Object.assign({}, consumers);
        if (active)
            next[key] = true;
        else
            delete next[key];
        consumers = next;
        if (consumerCount === 0)
            stopOwnedScan();
    }

    function setEnabled(value) {
        if (!adapter)
            return false;
        if (!value)
            stopOwnedScan();
        adapter.enabled = value === true;
        return true;
    }

    function scan() {
        if (!adapter || !enabled || consumerCount === 0)
            return false;
        error = "";
        if (!adapter.discovering) {
            adapter.discovering = true;
            scanOwned = true;
        }
        scanTimeout.restart();
        return true;
    }

    function stopOwnedScan() {
        scanTimeout.stop();
        if (scanOwned && adapter?.discovering)
            adapter.discovering = false;
        scanOwned = false;
    }

    function selectDevice(address) {
        const device = devices.find(candidate => candidate.address === address);
        if (!device)
            return false;
        selectedAddress = address;
        error = "";
        return true;
    }

    function connectSelected() {
        if (!selectedDevice || !enabled || selectedDevice.connected)
            return false;
        error = "";
        selectedDevice.connect();
        return true;
    }

    function disconnectSelected() {
        if (!selectedDevice?.connected)
            return false;
        error = "";
        selectedDevice.disconnect();
        return true;
    }

    function pairSelected() {
        if (!selectedDevice || !enabled || selectedDevice.paired || selectedDevice.pairing)
            return false;
        error = "";
        selectedDevice.pair();
        return true;
    }

    function cancelPairing() {
        if (!selectedDevice?.pairing)
            return false;
        selectedDevice.cancelPair();
        return true;
    }

    function setTrusted(value) {
        if (!selectedDevice?.paired)
            return false;
        selectedDevice.trusted = value === true;
        return true;
    }

    function forgetSelected() {
        if (!selectedDevice || !selectedDevice.paired && !selectedDevice.trusted)
            return false;
        selectedDevice.forget();
        selectedAddress = "";
        return true;
    }

    function snapshot() {
        return {
            available: available,
            enabled: enabled,
            scanning: scanning,
            adapterName: adapter?.name || "",
            adapterDeviceCount: adapter?.devices?.values?.length ?? 0,
            globalDeviceCount: Bluetooth.devices?.values?.length ?? 0,
            selectedAddress: selectedAddress,
            devices: devices.map(device => ({
                        address: device.address,
                        name: Model.deviceLabel(device),
                        state: Model.deviceState(device),
                        connected: device.connected,
                        paired: device.paired,
                        trusted: device.trusted,
                        battery: device.connected && device.batteryAvailable ? Math.round(device.battery * 100) : null
                    }))
        };
    }

    onEnabledChanged: {
        if (!enabled)
            stopOwnedScan();
    }

    Timer {
        id: scanTimeout
        interval: 20000
        onTriggered: root.stopOwnedScan()
    }
}
