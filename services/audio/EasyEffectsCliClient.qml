import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool busy: false
    property int token: 0
    property var command: []

    signal completed(int token, string response)
    signal failed(int token, string code, string message)

    visible: false
    width: 0
    height: 0

    function request(nextCommand, nextToken) {
        if (busy || !Array.isArray(nextCommand) || nextCommand.length === 0)
            return false;
        token = Math.max(0, Math.trunc(Number(nextToken) || 0));
        command = nextCommand.slice();
        busy = true;
        timeout.restart();
        process.command = command;
        process.running = true;
        return true;
    }

    function reset() {
        timeout.stop();
        if (process.running)
            process.running = false;
        busy = false;
        token = 0;
        command = [];
    }

    Process {
        id: process
        property string output: ""
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: process.output = text
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (!root.busy)
                return;
            const completedToken = root.token;
            const response = output;
            output = "";
            root.reset();
            if (Number(exitCode) === 0)
                root.completed(completedToken, response);
            else
                root.failed(completedToken, "cli-failed", "The EasyEffects command fallback failed.");
        }
    }

    Timer {
        id: timeout
        interval: 1800
        onTriggered: {
            const failedToken = root.token;
            root.reset();
            root.failed(failedToken, "cli-timeout", "The EasyEffects command fallback timed out.");
        }
    }

    Component.onDestruction: reset()
}
