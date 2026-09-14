pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "WallpaperProjectModel.js" as ProjectModel
import "WallpaperPortableProjectModel.js" as PortableProject
import "WallpaperProjectBundleModel.js" as Bundle
import "WallpaperDraftPublicationValidation.js" as Validation
import "WallpaperPublishedProjectModel.js" as PublishedProject
import "WallpaperPublishedProjectInspectionFlow.js" as InspectionFlow
import "../../../core/JsonCopy.js" as JsonCopy

Singleton {
    id: root

    property bool busy: false
    property string state: "idle"
    property string error: ""
    property real progress: 0
    property string rootPath: ""
    property string processOutput: ""
    property bool timedOut: false
    property var projectManifest: null
    property var bundleManifest: null
    property string inventoryOutput: ""
    property var verificationQueue: []
    property var activeFile: null
    property var evidence: []
    property var result: null

    signal finished(bool accepted, string error, var result)

    function reset() {
        if (busy)
            return false;
        state = "idle";
        error = "";
        progress = 0;
        rootPath = "";
        projectManifest = null;
        bundleManifest = null;
        inventoryOutput = "";
        verificationQueue = [];
        activeFile = null;
        evidence = [];
        result = null;
        return true;
    }

    function request(path) {
        if (busy)
            return false;
        reset();
        rootPath = ProjectModel.normalizedSourcePath(path);
        if (!rootPath)
            return reject("Project folder must be absolute");
        busy = true;
        progress = 0.02;
        run("checking-root", ["test", "-d", rootPath, "-a", "-r", rootPath + "/project.json", "-a", "-r", rootPath + "/bundle.json"], 10000);
        return true;
    }

    function run(nextState, command, timeoutMs) {
        state = nextState;
        processOutput = "";
        timedOut = false;
        worker.command = command;
        worker.running = true;
        operationTimeout.interval = Math.max(1000, Math.min(1800000, Number(timeoutMs) || 10000));
        operationTimeout.restart();
    }

    function transferTimeout(sizeBytes) {
        return Math.max(30000, Math.min(1800000, Math.ceil(Math.max(0, Number(sizeBytes) || 0) / 5242880) * 1000 + 30000));
    }

    function reject(message) {
        busy = false;
        state = "failed";
        error = String(message || "Project inspection failed");
        result = null;
        finished(false, error, null);
        return false;
    }

    function parseProjectManifest() {
        try {
            const parsed = PortableProject.parse(JSON.parse(processOutput));
            if (!parsed.accepted)
                return reject(parsed.error);
            projectManifest = parsed.document;
            progress = 0.14;
            run("reading-bundle", ["cat", "--", rootPath + "/bundle.json"], 10000);
        } catch (exception) {
            reject("Project manifest is not valid JSON");
        }
    }

    function parseBundleManifest() {
        try {
            const parsed = Bundle.parse(JSON.parse(processOutput));
            if (!parsed.accepted)
                return reject(parsed.error);
            bundleManifest = parsed.document;
            progress = 0.24;
            run("checking-symlinks", ["find", rootPath, "-type", "l", "-print", "-quit"], 10000);
        } catch (exception) {
            reject("Bundle manifest is not valid JSON");
        }
    }

    function prepareVerification() {
        inventoryOutput = processOutput;
        if (!Validation.acceptsInventory(bundleManifest, inventoryOutput))
            return reject("Project file inventory does not match its bundle");
        evidence = [
            {
                relativePath: "project.json",
                sizeBytes: 0,
                identity: "manifest"
            },
            {
                relativePath: "bundle.json",
                sizeBytes: 0,
                identity: "manifest"
            }
        ];
        verificationQueue = bundleManifest.workspace.files.slice();
        progress = 0.34;
        verifyNext();
    }

    function verifyNext() {
        if (verificationQueue.length === 0)
            return finishValidation();
        const queue = verificationQueue.slice();
        activeFile = queue.shift();
        verificationQueue = queue;
        const total = bundleManifest.workspace.files.length;
        const completed = total - queue.length - 1;
        progress = 0.34 + 0.56 * completed / Math.max(1, total);
        run("verifying-size", ["stat", "--printf=%s", "--", rootPath + "/" + activeFile.relativePath], 10000);
    }

    function acceptSize() {
        if (!Validation.acceptsSize(activeFile, processOutput))
            return reject("Project file size does not match: " + activeFile.relativePath);
        run("verifying-identity", ["sha256sum", "--", rootPath + "/" + activeFile.relativePath], transferTimeout(activeFile.sizeBytes));
    }

    function acceptIdentity() {
        if (!Validation.acceptsIdentity(activeFile, processOutput))
            return reject("Project file identity does not match: " + activeFile.relativePath);
        evidence = evidence.concat([
            {
                relativePath: activeFile.relativePath,
                sizeBytes: activeFile.sizeBytes,
                identity: activeFile.identity
            }
        ]);
        activeFile = null;
        verifyNext();
    }

    function finishValidation() {
        const validation = PublishedProject.validate({
            rootPath: rootPath,
            projectManifest: projectManifest,
            bundleManifest: bundleManifest,
            files: evidence,
            symlinks: []
        });
        if (!validation.accepted)
            return reject(validation.error);
        busy = false;
        state = "ready";
        error = "";
        progress = 1;
        result = JsonCopy.value(validation);
        finished(true, "", JsonCopy.value(result));
    }

    function applyAction(action) {
        if (action.kind === "fail")
            return reject(action.message);
        if (action.kind === "run")
            return run(action.state, action.command, action.timeoutMs);
        const calls = ({
                "parse-project": parseProjectManifest,
                "parse-bundle": parseBundleManifest,
                "prepare-verification": prepareVerification,
                "accept-size": acceptSize,
                "accept-identity": acceptIdentity
            });
        const handler = calls[action.name];
        if (handler)
            return handler();
        reject("Unknown project inspection action: " + action.name);
    }

    function processFinished(exitCode) {
        operationTimeout.stop();
        if (!busy)
            return;
        if (timedOut) {
            timedOut = false;
            reject("Project inspection timed out during " + state);
            return;
        }
        applyAction(InspectionFlow.next(state, exitCode, processOutput, {
            rootPath: rootPath
        }));
    }

    function snapshot() {
        return JsonCopy.value({
            busy: busy,
            state: state,
            error: error,
            progress: progress,
            rootPath: rootPath,
            filesTotal: bundleManifest?.workspace?.files?.length || 0,
            filesRemaining: verificationQueue.length,
            accepted: result?.accepted === true,
            projectId: result?.projectDocument?.project?.id || ""
        });
    }

    Timer {
        id: operationTimeout
        onTriggered: {
            if (!worker.running)
                return;
            root.timedOut = true;
            worker.running = false;
        }
    }

    Process {
        id: worker
        stdout: StdioCollector {
            onStreamFinished: root.processOutput = text
        }
        onExited: exitCode => root.processFinished(exitCode)
    }
}
