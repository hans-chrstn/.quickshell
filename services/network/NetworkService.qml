pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "NetworkModel.js" as Model

Singleton {
    id: root

    property bool networkdAvailable: false
    property bool networkManagerAvailable: false
    property var networkdLinks: []
    property var consumers: ({})
    readonly property string backend: networkManagerAvailable && networkManagerProvider.item ? "networkmanager" : networkdAvailable ? "networkd" : "none"
    readonly property var wiredLinks: backend === "networkmanager" ? networkManagerProvider.item.wiredLinks : networkdLinks.filter(link => link.type === "wired")
    readonly property int consumerCount: Object.keys(consumers).length

    Component.onCompleted: refresh()

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
        if (active)
            refresh();
    }

    function refresh() {
        if (!networkManagerProbe.running)
            networkManagerProbe.running = true;
        if (!networkdProcess.running)
            networkdProcess.running = true;
    }

    function snapshot() {
        return {
            backend: backend,
            wiredLinks: wiredLinks,
            networkManagerAvailable: networkManagerAvailable,
            networkdAvailable: networkdAvailable
        };
    }

    Timer {
        interval: 8000
        repeat: true
        running: root.consumerCount > 0
        onTriggered: root.refresh()
    }

    Loader {
        id: networkManagerProvider
        active: root.networkManagerAvailable
        sourceComponent: Component {
            NetworkManagerProvider {}
        }
    }

    Process {
        id: networkManagerProbe
        command: ["env", "nmcli", "-t", "-f", "RUNNING", "general"]
        stdout: StdioCollector {
            onStreamFinished: root.networkManagerAvailable = text.trim() === "running"
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode !== 0)
                root.networkManagerAvailable = false;
        }
    }

    Process {
        id: networkdProcess
        property string output: ""
        command: ["env", "networkctl", "--json=short", "list", "--no-pager"]
        stdout: StdioCollector {
            onStreamFinished: networkdProcess.output = text
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.networkdAvailable = false;
                root.networkdLinks = [];
                return;
            }
            try {
                const payload = JSON.parse(output);
                if (!Array.isArray(payload.Interfaces))
                    throw new Error("Invalid network response");
                root.networkdLinks = Model.normalizeNetworkd(payload);
                root.networkdAvailable = true;
            } catch (error) {
                root.networkdAvailable = false;
                root.networkdLinks = [];
            }
        }
    }
}
