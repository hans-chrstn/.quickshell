import QtQuick
import Quickshell
import Quickshell.Io
import "EasyEffectsProtocol.js" as EasyEffectsProtocol

Item {
    id: root

    property bool busy: false
    property int generation: 0
    property bool nativeDone: false
    property bool flatpakDone: false
    property bool runningDone: false
    property bool presetsDone: false
    property string nativeOutput: ""
    property string flatpakExecutableOutput: ""
    property string flatpakOutput: ""
    property int flatpakExitCode: -1
    property bool processRunning: false
    property string presetOutput: ""
    readonly property string homePath: String(Quickshell.env("HOME") || "").replace(/\/+$/, "")
    readonly property string flatpakRoot: homePath.length > 0 ? homePath + "/.var/app/com.github.wwmm.easyeffects" : ""
    readonly property var pathDirectories: EasyEffectsProtocol.normalizedAbsolutePaths(String(Quickshell.env("PATH") || "").split(":"), 128)
    readonly property var presetRoots: buildPresetRoots()

    signal completed(var result)

    visible: false
    width: 0
    height: 0

    function splitEnvironment(value, fallback) {
        const source = String(value || "").trim();
        return (source.length > 0 ? source : fallback).split(":");
    }

    function buildPresetRoots() {
        const roots = [];
        const dataHome = String(Quickshell.env("XDG_DATA_HOME") || "").trim();
        const configHome = String(Quickshell.env("XDG_CONFIG_HOME") || "").trim();
        if (dataHome.length > 0)
            roots.push(dataHome + "/easyeffects");
        else if (homePath.length > 0)
            roots.push(homePath + "/.local/share/easyeffects");
        for (const path of splitEnvironment(Quickshell.env("XDG_DATA_DIRS"), "/usr/local/share:/usr/share"))
            roots.push(path + "/easyeffects");
        if (configHome.length > 0)
            roots.push(configHome + "/easyeffects");
        else if (homePath.length > 0)
            roots.push(homePath + "/.config/easyeffects");
        for (const path of splitEnvironment(Quickshell.env("XDG_CONFIG_DIRS"), "/etc/xdg"))
            roots.push(path + "/easyeffects");
        if (flatpakRoot.length > 0) {
            roots.push(flatpakRoot + "/data/easyeffects");
            roots.push(flatpakRoot + "/config/easyeffects");
        }
        return EasyEffectsProtocol.normalizedAbsolutePaths(roots, 32);
    }

    function refresh() {
        if (busy)
            return false;
        generation += 1;
        busy = true;
        nativeDone = pathDirectories.length === 0;
        flatpakDone = pathDirectories.length === 0;
        runningDone = pathDirectories.length === 0;
        presetsDone = presetRoots.length === 0;
        nativeOutput = "";
        flatpakExecutableOutput = "";
        flatpakOutput = "";
        flatpakExitCode = -1;
        processRunning = false;
        presetOutput = "";
        if (!nativeDone) {
            nativeCheck.command = ["find", "-L"].concat(pathDirectories, ["-maxdepth", "1", "-type", "f", "-executable", "(", "-name", "easyeffects", "-o", "-name", "flatpak", "-o", "-name", "pgrep", ")", "-print"]);
            nativeCheck.running = true;
        }
        if (!presetsDone) {
            presetScan.command = ["find"].concat(presetRoots, ["-maxdepth", "2", "-type", "f", "-name", "*.json", "-print"]);
            presetScan.running = true;
        }
        finishIfComplete();
        return true;
    }

    function toolPath(output, name) {
        const suffix = "/" + name;
        const paths = EasyEffectsProtocol.normalizedAbsolutePaths(String(output || "").split(/\r?\n/), 128);
        return paths.find(path => path.endsWith(suffix)) || "";
    }

    function finishIfComplete() {
        if (!busy || !nativeDone || !flatpakDone || !runningDone || !presetsDone)
            return;
        const installation = EasyEffectsProtocol.installation(nativeOutput, flatpakExitCode, flatpakOutput, flatpakExecutableOutput);
        const inventory = EasyEffectsProtocol.presetInventoryFromPaths(presetOutput.split(/\r?\n/));
        busy = false;
        completed({
            generation: generation,
            nativeInstalled: installation.nativeInstalled,
            nativePath: installation.nativePath,
            flatpakInstalled: installation.flatpakInstalled,
            flatpakPath: installation.flatpakPath,
            processRunning: processRunning,
            outputPresets: inventory.output,
            inputPresets: inventory.input
        });
    }

    Process {
        id: nativeCheck
        property string output: ""
        stdout: StdioCollector {
            onStreamFinished: nativeCheck.output = text
        }
        stderr: StdioCollector {}
        onExited: {
            const easyEffectsPath = root.toolPath(output, "easyeffects");
            const flatpakPath = root.toolPath(output, "flatpak");
            const pgrepPath = root.toolPath(output, "pgrep");
            root.nativeOutput = easyEffectsPath;
            root.flatpakExecutableOutput = flatpakPath;
            root.nativeDone = true;
            if (flatpakPath.length > 0) {
                flatpakCheck.command = [flatpakPath, "info", "--show-location", "com.github.wwmm.easyeffects"];
                flatpakCheck.running = true;
            } else {
                root.flatpakDone = true;
            }
            if (pgrepPath.length > 0) {
                runningCheck.command = [pgrepPath, "-x", "easyeffects"];
                runningCheck.running = true;
            } else {
                root.runningDone = true;
            }
            root.finishIfComplete();
        }
    }

    Process {
        id: flatpakCheck
        property string output: ""
        stdout: StdioCollector {
            onStreamFinished: flatpakCheck.output = text
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            root.flatpakOutput = output;
            root.flatpakExitCode = Number(exitCode);
            root.flatpakDone = true;
            root.finishIfComplete();
        }
    }

    Process {
        id: presetScan
        property string output: ""
        stdout: StdioCollector {
            onStreamFinished: presetScan.output = text
        }
        stderr: StdioCollector {}
        onExited: {
            root.presetOutput = output;
            root.presetsDone = true;
            root.finishIfComplete();
        }
    }

    Process {
        id: runningCheck
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => {
            root.processRunning = Number(exitCode) === 0;
            root.runningDone = true;
            root.finishIfComplete();
        }
    }
}
