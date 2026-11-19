import QtQuick
import Quickshell.Networking

QtObject {
    readonly property var wiredLinks: Networking.devices.values.filter(device => device.type === DeviceType.Wired).map(device => ({
                id: device.name,
                name: device.name,
                type: "wired",
                connected: device.connected,
                state: ConnectionState.toString(device.state),
                address: "",
                hardwareAddress: device.address,
                model: "",
                carrier: device.connected,
                managed: device.nmManaged,
                speed: device.linkSpeed || 0
            }))
}
