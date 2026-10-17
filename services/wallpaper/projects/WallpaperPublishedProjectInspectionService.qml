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
    property int generation: 0
    property int activeRequestId: 0
    property int workerRequestId: 0
    property int timeoutRequestId: 0
    property bool workerDraining: false
    property int requestCount: 0
    property int cancelCount: 0
    property int staleCompletionCount: 0
    property var projectManifest: null
    property var bundleManifest: null
    property string inventoryOutput: ""
    property var verificationQueue: []
    property var activeFile: null
    property var evidence: []
    property var result: null

    signal finished(bool accepted, string error, var result, int requestId)
    signal cancelled(int requestId)

    readonly property bool readyForRequest: !busy && !worker.running && !workerDraining

    function reset() {
        if (!readyForRequest)
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
        activeRequestId = 0;
        workerRequestId = 0;
        timeoutRequestId = 0;
        timedOut = false;
        return true;
    }

    function request(path) {
        if (!readyForRequest)
            return false;
        reset();
        generation += 1;
        activeRequestId = generation;
        requestCount += 1;
        rootPath = ProjectModel.normalizedSourcePath(path);
        if (!rootPath)
            return reject("Project folder must be absolute");
        busy = true;
        progress = 0.02;
        run("checking-root", ["test", "-d", rootPath, "-a", "-r", rootPath + "/project.json", "-a", "-r", rootPath + "/bundle.json"], 10000);
        return activeRequestId;
    }

    function run(nextState, command, timeoutMs) {
        if (!busy || activeRequestId <= 0)
            return false;
        state = nextState;
        processOutput = "";
        timedOut = false;
        workerRequestId = activeRequestId;
        timeoutRequestId = activeRequestId;
        worker.command = command;
        worker.running = true;
        operationTimeout.interval = Math.max(1000, Math.min(1800000, Number(timeoutMs) || 10000));
        operationTimeout.restart();
        return true;
    }

    function transferTimeout(sizeBytes) {
        return Math.max(30000, Math.min(1800000, Math.ceil(Math.max(0, Number(sizeBytes) || 0) / 5242880) * 1000 + 30000));
    }

    function reject(message) {
        const requestId = activeRequestId;
        busy = false;
        activeRequestId = 0;
        workerRequestId = 0;
        state = "failed";
        error = String(message || "Project inspection failed");
        result = null;
        finished(false, error, null, requestId);
        return false;
    }

    function cancel(requestId) {
        const expectedId = Math.max(0, Number(requestId) || 0);
        if (!busy || activeRequestId <= 0 || (expectedId > 0 && expectedId !== activeRequestId))
            return false;
        const cancelledId = activeRequestId;
        operationTimeout.stop();
        timeoutRequestId = 0;
        busy = false;
        activeRequestId = 0;
        state = "cancelled";
        error = "";
        progress = 0;
        verificationQueue = [];
        activeFile = null;
        result = null;
        cancelCount += 1;
        if (worker.running) {
            workerDraining = true;
            worker.running = false;
        }
        cancelled(cancelledId);
        return true;
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
        const requestId = activeRequestId;
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
        activeRequestId = 0;
        workerRequestId = 0;
        state = "ready";
        error = "";
        progress = 1;
        result = JsonCopy.value(validation);
        finished(true, "", JsonCopy.value(result), requestId);
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

    function processFinished(requestId, exitCode) {
        operationTimeout.stop();
        timeoutRequestId = 0;
        if (!busy || requestId <= 0 || requestId !== activeRequestId) {
            if (requestId > 0)
                staleCompletionCount += 1;
            return;
        }
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
            readyForRequest: readyForRequest,
            state: state,
            error: error,
            progress: progress,
            rootPath: rootPath,
            activeRequestId: activeRequestId,
            workerRequestId: workerRequestId,
            workerDraining: workerDraining,
            requestCount: requestCount,
            cancelCount: cancelCount,
            staleCompletionCount: staleCompletionCount,
            filesTotal: bundleManifest?.workspace?.files?.length || 0,
            filesRemaining: verificationQueue.length,
            accepted: result?.accepted === true,
            projectId: result?.projectDocument?.project?.id || ""
        });
    }

    Timer {
        id: operationTimeout
        onTriggered: {
            if (!worker.running || root.timeoutRequestId <= 0 || root.timeoutRequestId !== root.activeRequestId)
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
        onExited: exitCode => {
            const requestId = root.workerRequestId;
            root.processFinished(requestId, exitCode);
            if (root.workerDraining) {
                root.workerDraining = false;
                root.workerRequestId = 0;
            }
        }
    }
}
