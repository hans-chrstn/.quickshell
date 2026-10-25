pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "WallpaperDraftSavePlan.js" as SavePlan
import "WallpaperProjectBundleModel.js" as Bundle
import "WallpaperPortableProjectModel.js" as PortableProject
import "WallpaperDraftPublicationFlow.js" as PublicationFlow
import "WallpaperDraftPublicationValidation.js" as PublicationValidation
import "../../../core/JsonCopy.js" as JsonCopy

Singleton {
    id: root

    property bool busy: false
    property string state: "idle"
    property string error: ""
    property real progress: 0
    property var plan: null
    property int generation: 0
    property var originalDocument: null
    property var completedDocument: null
    property var portableDocument: null
    property var verificationQueue: []
    property var excludedPaths: []
    property var activeFile: null
    property string processOutput: ""
    property string awaitedWriteToken: ""
    property string pendingError: ""
    property bool manifestStarted: false
    property bool stagingCreated: false
    property bool published: false
    property bool timedOut: false

    signal finished(bool accepted, string error)

    function reset() {
        if (busy)
            return false;
        state = "idle";
        error = "";
        progress = 0;
        plan = null;
        return true;
    }

    function request(workspaceId, parentPath, folderName) {
        if (busy)
            return false;
        clearOperation();
        const workspace = WallpaperDraftWorkspaceService.workspaceSnapshot(workspaceId);
        generation += 1;
        const result = SavePlan.create({
            parentPath: parentPath,
            folderName: folderName,
            operationId: "publish-" + generation
        }, workspace?.entry, workspace?.manifest, Date.now());
        if (!result.accepted) {
            reject(result.error);
            return false;
        }
        const project = WallpaperProjectService.projectSnapshot(result.plan.projectId);
        const portable = PortableProject.create(project, Date.now());
        if (!portable.accepted) {
            reject(portable.error);
            return false;
        }
        const publishableBundle = PublicationValidation.publicationDocument(result.plan.savingDocument, project);
        if (!publishableBundle) {
            reject("Publishable project assets could not be derived");
            return false;
        }
        const completed = Bundle.completeSave(publishableBundle, Date.now());
        if (!completed.accepted) {
            reject(completed.error);
            return false;
        }

        plan = result.plan;
        originalDocument = workspace.manifest;
        completedDocument = completed.document;
        excludedPaths = PublicationValidation.excludedPaths(workspace.manifest, completedDocument);
        portableDocument = portable.document;
        busy = true;
        error = "";
        progress = 0.02;
        run("checking-parent", ["test", "-d", plan.parentPath, "-a", "-w", plan.parentPath], 10000);
        return true;
    }

    function clearOperation() {
        plan = null;
        originalDocument = null;
        completedDocument = null;
        portableDocument = null;
        verificationQueue = [];
        excludedPaths = [];
        activeFile = null;
        processOutput = "";
        awaitedWriteToken = "";
        pendingError = "";
        manifestStarted = false;
        stagingCreated = false;
        published = false;
        timedOut = false;
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

    function totalFileBytes() {
        return completedDocument.workspace.files.reduce((total, file) => total + Math.max(0, Number(file.sizeBytes) || 0), 0);
    }

    function safeStagingPath() {
        if (!plan)
            return false;
        const prefix = plan.parentPath === "/" ? "/." : plan.parentPath + "/.";
        return plan.stagingPath !== plan.parentPath && plan.stagingPath.startsWith(prefix);
    }

    function persistSavingManifest() {
        state = "persisting-saving-manifest";
        progress = 0.12;
        awaitedWriteToken = "publication-start:" + generation;
        if (!WallpaperDraftWorkspaceService.requestManifestWrite(plan.workspaceId, plan.savingDocument, awaitedWriteToken))
            fail("Draft saving state could not be written");
    }

    function createStaging() {
        progress = 0.18;
        run("creating-staging", ["mkdir", "--", plan.stagingPath], 10000);
    }

    function copyDraft() {
        stagingCreated = true;
        progress = 0.25;
        run("copying-draft", ["cp", "-a", "--reflink=auto", "--", plan.sourceRootPath + "/.", plan.stagingPath], transferTimeout(totalFileBytes()));
    }

    function writeStagedManifests() {
        state = "writing-staged-manifests";
        progress = 0.48;
        stagedProjectFile.path = plan.stagingPath + "/project.json";
        stagedProjectData.formatId = portableDocument.formatId;
        stagedProjectData.schemaVersion = portableDocument.schemaVersion;
        stagedProjectData.projectId = portableDocument.projectId;
        stagedProjectData.savedAtMs = portableDocument.savedAtMs;
        stagedProjectData.projectDocument = JsonCopy.value(portableDocument.projectDocument);
        stagedBundleFile.path = plan.stagingPath + "/bundle.json";
        stagedBundleData.schemaVersion = completedDocument.schemaVersion;
        stagedBundleData.workspace = JsonCopy.value(completedDocument.workspace);
        stagedProjectFile.writeAdapter();
        stagedBundleFile.writeAdapter();
        stagedManifestDelay.restart();
    }

    function removeExcludedFiles() {
        if (excludedPaths.length === 0) {
            writeStagedManifests();
            return;
        }
        const command = ["rm", "-f", "--"];
        for (const path of excludedPaths)
            command.push(plan.stagingPath + "/" + path);
        run("removing-unreferenced-files", command, 30000);
    }

    function verifyNextFile() {
        if (verificationQueue.length === 0) {
            publishStaging();
            return;
        }
        const queue = verificationQueue.slice();
        activeFile = queue.shift();
        verificationQueue = queue;
        const verified = completedDocument.workspace.files.length - verificationQueue.length - 1;
        progress = 0.62 + 0.22 * verified / Math.max(1, completedDocument.workspace.files.length);
        run("verifying-file-size", ["stat", "--printf=%s", "--", plan.stagingPath + "/" + activeFile.relativePath], 10000);
    }

    function publishStaging() {
        progress = 0.88;
        run("publishing", ["mv", "-T", "--no-clobber", "--", plan.stagingPath, plan.destinationPath], 30000);
    }

    function persistCompletedManifest() {
        state = "persisting-completed-manifest";
        progress = 0.97;
        awaitedWriteToken = "publication-complete:" + generation;
        if (!WallpaperDraftWorkspaceService.requestManifestWrite(plan.workspaceId, completedDocument, awaitedWriteToken))
            finishPublished("Project was published, but draft status could not be updated");
    }

    function fail(message) {
        if (!busy)
            return;
        pendingError = String(message || "Project publication failed");
        operationTimeout.stop();
        stagedManifestDelay.stop();
        if (!published && stagingCreated && safeStagingPath()) {
            run("cleaning-staging", ["rm", "-rf", "--", plan.stagingPath], 30000);
            return;
        }
        restoreOrFinish();
    }

    function restoreOrFinish() {
        if (manifestStarted && originalDocument) {
            state = "restoring-draft-manifest";
            awaitedWriteToken = "publication-restore:" + generation;
            if (WallpaperDraftWorkspaceService.requestManifestWrite(plan.workspaceId, originalDocument, awaitedWriteToken))
                return;
        }
        finishFailure();
    }

    function reject(message) {
        busy = false;
        state = "failed";
        error = String(message || "Project publication failed");
        finished(false, error);
    }

    function finishFailure() {
        const message = pendingError || "Project publication failed";
        busy = false;
        state = "failed";
        error = message;
        awaitedWriteToken = "";
        finished(false, message);
    }

    function finishPublished(warning) {
        busy = false;
        progress = 1;
        error = String(warning || "");
        state = error.length > 0 ? "published-with-warning" : "saved";
        awaitedWriteToken = "";
        finished(true, error);
    }

    function snapshot() {
        return JsonCopy.value({
            busy: busy,
            state: state,
            error: error,
            progress: progress,
            destinationPath: plan?.destinationPath || "",
            stagingPath: plan?.stagingPath || "",
            strategy: plan?.publicationStrategy || "",
            filesTotal: completedDocument?.workspace?.files?.length || 0,
            filesRemaining: verificationQueue.length,
            published: published
        });
    }

    Connections {
        target: WallpaperDraftWorkspaceService

        function onManifestWriteFinished(token, accepted, writeError) {
            if (token !== root.awaitedWriteToken)
                return;
            root.awaitedWriteToken = "";
            if (token.startsWith("publication-start:")) {
                if (!accepted)
                    root.fail(writeError);
                else {
                    root.manifestStarted = true;
                    root.createStaging();
                }
            } else if (token.startsWith("publication-complete:")) {
                root.finishPublished(accepted ? "" : "Project was published, but draft status could not be updated");
            } else if (token.startsWith("publication-restore:")) {
                root.finishFailure();
            }
        }
    }

    Timer {
        id: stagedManifestDelay
        interval: 80
        onTriggered: root.run("verifying-project-manifest", ["cat", "--", root.plan.stagingPath + "/project.json"], 10000)
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

    function processFinished(exitCode) {
        operationTimeout.stop();
        if (!busy)
            return;
        if (timedOut) {
            timedOut = false;
            fail("Project publication timed out during " + state);
            return;
        }
        const action = PublicationFlow.next(state, exitCode, processOutput, {
            plan: plan,
            completedDocument: completedDocument,
            activeFile: activeFile,
            transferTimeout: transferTimeout
        });
        applyAction(action);
    }

    function applyAction(action) {
        if (action.kind === "fail")
            return fail(action.message);
        if (action.kind === "run")
            return run(action.state, action.command, action.timeoutMs);
        const calls = ({
                "persist-saving": persistSavingManifest,
                "copy-draft": copyDraft,
                "write-manifests": removeExcludedFiles,
                "write-staged-manifests": writeStagedManifests,
                "begin-file-verification": () => {
                    progress = 0.54;
                    verificationQueue = completedDocument.workspace.files.slice();
                    verifyNextFile();
                },
                "verify-next-file": () => {
                    activeFile = null;
                    verifyNextFile();
                },
                "persist-completed": () => {
                    published = true;
                    stagingCreated = false;
                    persistCompletedManifest();
                },
                "restore-or-finish": () => {
                    stagingCreated = false;
                    restoreOrFinish();
                }
            });
        const handler = calls[action.name];
        if (handler)
            return handler();
        fail("Unknown publication action: " + action.name);
    }

    FileView {
        id: stagedProjectFile
        path: ""
        printErrors: false
        JsonAdapter {
            id: stagedProjectData
            property string formatId: ""
            property int schemaVersion: 1
            property string projectId: ""
            property double savedAtMs: 0
            property var projectDocument: ({})
        }
    }

    FileView {
        id: stagedBundleFile
        path: ""
        printErrors: false
        JsonAdapter {
            id: stagedBundleData
            property int schemaVersion: 1
            property var workspace: ({})
        }
    }
}
