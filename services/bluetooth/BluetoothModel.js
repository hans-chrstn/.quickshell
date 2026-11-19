.pragma library

function sortDevices(devices) {
    const values = devices && typeof devices.filter === "function" ? devices.filter(device => device && String(device.address || "").length > 0) : [];
    return values.sort((left, right) => Number(right.connected) - Number(left.connected) || Number(right.paired || right.trusted) - Number(left.paired || left.trusted) || String(left.name || left.deviceName || left.address).localeCompare(String(right.name || right.deviceName || right.address)));
}

function deviceLabel(device) {
    return String(device?.name || device?.deviceName || device?.address || "Unknown device");
}

function deviceState(device) {
    if (device?.pairing)
        return "Pairing";
    if (device?.connected)
        return "Connected";
    if (device?.state === 3)
        return "Connecting";
    if (device?.state === 2)
        return "Disconnecting";
    if (device?.paired)
        return "Paired";
    if (device?.trusted)
        return "Trusted";
    return "Available";
}
