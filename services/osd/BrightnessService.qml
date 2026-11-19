pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "OsdModel.js" as Model

Singleton {
    id: root

    property string deviceName: ""
    property real maximum: 0
    property real current: 0
    property bool available: false
    property bool initialized: false
    readonly property real level: maximum > 0 ? Math.max(0, Math.min(1, current / maximum)) : 0

    signal changed(real level)

    function updateValue(value) {
        const numeric = Number(value);
        if (!Number.isFinite(numeric))
            return;
        const previous = current;
        current = numeric;
        if (initialized && Math.abs(previous - numeric) >= 1)
            changed(level);
        initialized = true;
    }

    Component.onCompleted: probe.running = true

    Process {
        id: probe
        property string output: ""
        command: ["env", "brightnessctl", "-l", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: probe.output = text
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            const record = exitCode === 0 ? Model.backlightFromBrightnessctl(output) : null;
            root.deviceName = record?.name || "";
            root.maximum = record?.maximum || 0;
            root.current = record?.current || 0;
            root.available = record !== null;
            root.initialized = record !== null;
        }
    }

    FileView {
        id: levelFile
        path: root.available ? "/sys/class/backlight/" + root.deviceName + "/brightness" : ""
        watchChanges: root.available
        printErrors: false
        onLoaded: root.updateValue(text.trim())
        onFileChanged: reload()
    }
}
