import QtQuick
import QtTest
import "../../services/bluetooth/BluetoothModel.js" as Model

TestCase {
    name: "BluetoothModel"

    function test_devicePriorityAndStableIdentity() {
        const devices = Model.sortDevices([
            {
                address: "C",
                name: "Keyboard",
                paired: false,
                connected: false
            },
            {
                address: "B",
                name: "Headphones",
                paired: true,
                connected: false
            },
            {
                address: "A",
                name: "Speaker",
                paired: true,
                connected: true
            },
            {
                address: "",
                name: "Invalid"
            }
        ]);
        compare(devices.length, 3);
        compare(devices[0].address, "A");
        compare(devices[1].address, "B");
        compare(devices[2].address, "C");
    }

    function test_deviceStatesAndEmptyInput() {
        compare(Model.sortDevices(null).length, 0);
        compare(Model.deviceState({
            pairing: true,
            connected: false
        }), "Pairing");
        compare(Model.deviceState({
            connected: true
        }), "Connected");
        compare(Model.deviceState({
            paired: true
        }), "Paired");
        compare(Model.deviceState({
            trusted: true
        }), "Trusted");
        compare(Model.deviceState({}), "Available");
        compare(Model.deviceLabel({
            address: "AA:BB"
        }), "AA:BB");
    }
}
