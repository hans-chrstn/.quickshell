import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool busy: false
    property int token: 0
    property var commands: []
    property var results: []
    property int commandIndex: -1
    property string stdoutText: ""
    property string stderrText: ""
    property bool timedOut: false
    property bool cancelling: false

    signal completed(int token, var results)
    signal failed(int token, int commandIndex, string code, string message, var results)

    visible: false
    width: 0
    height: 0

    function run(nextCommands, nextToken) {
        if (busy || !Array.isArray(nextCommands) || nextCommands.length === 0)
            return false;
        const normalized = [];
        for (const step of nextCommands) {
            if (!Array.isArray(step?.command) || step.command.length === 0)
                return false;
            normalized.push(Object.assign({}, step, {
                command: step.command.map(value => String(value))
            }));
        }
        commands = normalized;
        results = [];
        commandIndex = -1;
        token = Math.max(0, Math.trunc(Number(nextToken) || 0));
        busy = true;
        cancelling = false;
        startNext();
        return true;
    }

    function startNext() {
        commandIndex += 1;
        if (commandIndex >= commands.length) {
            const completedToken = token;
            const completedResults = results.slice();
            reset();
            completed(completedToken, completedResults);
            return;
        }
        stdoutText = "";
        stderrText = "";
        timedOut = false;
        commandProcess.command = commands[commandIndex].command;
        commandProcess.running = true;
        commandTimeout.restart();
    }

    function cancel() {
        if (!busy)
            return false;
        cancelling = true;
        commandTimeout.stop();
        if (commandProcess.running)
            commandProcess.running = false;
        else
            reset();
        return true;
    }

    function reset() {
        commandTimeout.stop();
        busy = false;
        commands = [];
        results = [];
        commandIndex = -1;
        stdoutText = "";
        stderrText = "";
        timedOut = false;
        cancelling = false;
    }

    Timer {
        id: commandTimeout

        interval: 1400
        onTriggered: {
            root.timedOut = true;
            if (commandProcess.running)
                commandProcess.running = false;
        }
    }

    Process {
        id: commandProcess

        stdout: StdioCollector {
            onStreamFinished: root.stdoutText = text
        }
        stderr: StdioCollector {
            onStreamFinished: root.stderrText = text
        }
        onExited: exitCode => {
            commandTimeout.stop();
            if (!root.busy)
                return;
            if (root.cancelling) {
                root.reset();
                return;
            }
            const step = root.commands[root.commandIndex];
            const nextResults = root.results.slice();
            nextResults.push({
                kind: String(step?.kind || ""),
                streamId: Math.max(0, Math.trunc(Number(step?.streamId) || 0)),
                exitCode: Number(exitCode),
                stdout: root.stdoutText,
                stderr: root.stderrText
            });
            root.results = nextResults;
            if (root.timedOut || exitCode !== 0) {
                const failedToken = root.token;
                const failedIndex = root.commandIndex;
                const code = root.timedOut ? "command-timeout" : "command-failed";
                const message = root.stderrText.trim() || (root.timedOut ? "The audio route command timed out." : "The audio route command failed.");
                const failedResults = root.results.slice();
                root.reset();
                root.failed(failedToken, failedIndex, code, message, failedResults);
                return;
            }
            root.startNext();
        }
    }
}
