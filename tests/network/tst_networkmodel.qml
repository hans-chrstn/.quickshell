import QtQuick
import QtTest
import "../../services/network/NetworkModel.js" as Model

TestCase {
    name: "NetworkModel"

    function test_normalizesWiredDetailsAndDropsUnrelatedLinks() {
        const links = Model.normalizeNetworkd({
            Interfaces: [
                {
                    Name: "wlp9s0",
                    Type: "wlan",
                    OperationalState: "off",
                    CarrierState: "off"
                },
                {
                    Name: "enp18s0",
                    Type: "ether",
                    OperationalState: "off",
                    CarrierState: "off",
                    AdministrativeState: "unmanaged"
                },
                {
                    Name: "enp10s0",
                    Type: "ether",
                    OperationalState: "routable",
                    CarrierState: "carrier",
                    AdministrativeState: "configured",
                    Model: "RTL8125 Controller",
                    HardwareAddress: [116, 86, 60, 253, 19, 146],
                    Addresses: [
                        {
                            Family: 2,
                            AddressString: "192.168.110.2",
                            ScopeString: "global"
                        }
                    ],
                    Routes: [
                        {
                            Family: 2,
                            DestinationPrefixLength: 0,
                            GatewayString: "192.168.110.1"
                        }
                    ],
                    DNS: [
                        {
                            Family: 2,
                            AddressString: "192.168.110.1"
                        }
                    ]
                },
                {
                    Name: "lo",
                    Type: "loopback"
                }
            ]
        });

        compare(links.length, 3);
        compare(links[0].name, "enp10s0");
        compare(links[0].connected, true);
        compare(links[0].address, "192.168.110.2");
        compare(links[0].gateway, "192.168.110.1");
        compare(links[0].dns, "192.168.110.1");
        compare(links[0].hardwareAddress, "74:56:3c:fd:13:92");
        compare(links[1].connected, false);
        compare(links[1].managed, false);
    }

    function test_missingAndInvalidPayloadsStayEmpty() {
        compare(Model.normalizeNetworkd(null).length, 0);
        compare(Model.normalizeNetworkd({
            Interfaces: "invalid"
        }).length, 0);
        compare(Model.normalizeNetworkd({
            Interfaces: [
                {
                    Name: "",
                    Type: "ether"
                }
            ]
        }).length, 0);
    }
}
