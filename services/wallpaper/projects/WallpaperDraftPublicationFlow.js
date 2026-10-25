.pragma library
.import "WallpaperProjectBundleModel.js" as Bundle
.import "WallpaperPortableProjectModel.js" as PortableProject
.import "WallpaperDraftPublicationValidation.js" as Validation

function run(state, command, timeoutMs) {
    return ({
            kind: "run",
            state: state,
            command: command,
            timeoutMs: timeoutMs || 10000
        });
}

function fail(message) {
    return ({
            kind: "fail",
            message: message
        });
}

function call(name) {
    return ({
            kind: "call",
            name: name
        });
}

function parseProject(output, projectId) {
    try {
        const parsed = PortableProject.parse(JSON.parse(output));
        return parsed.accepted && parsed.document.projectId === projectId;
    } catch (exception) {
        return false;
    }
}

function parseBundle(output, projectId) {
    try {
        const parsed = Bundle.parse(JSON.parse(output));
        return parsed.accepted && parsed.document.workspace.projectId === projectId && parsed.document.workspace.state === "saved";
    } catch (exception) {
        return false;
    }
}

function next(state, exitCode, output, context) {
    const stateKey = String(state || "");
    const plan = context.plan;
    const failed = exitCode !== 0;
    const handlers = ({
            "checking-parent": () => failed ? fail("Save parent is unavailable or not writable") : run("checking-source", ["test", "-d", plan.sourceRootPath, "-a", "-r", plan.sourceManifestPath]),
            "checking-source": () => failed ? fail("Draft workspace is unavailable or unreadable") : run("checking-destination", ["test", "!", "-e", plan.destinationPath]),
            "checking-destination": () => failed ? fail("A file or folder already uses this project name") : run("checking-staging", ["test", "!", "-e", plan.stagingPath]),
            "checking-staging": () => failed ? fail("A previous save staging folder still exists") : call("persist-saving"),
            "creating-staging": () => failed ? fail("Destination staging folder could not be created") : call("copy-draft"),
            "copying-draft": () => failed ? fail("Draft files could not be copied to the destination") : call("write-manifests"),
            "removing-unreferenced-files": () => failed ? fail("Unreferenced draft cache could not be excluded") : call("write-staged-manifests"),
            "verifying-project-manifest": () => failed || !parseProject(output, plan.projectId) ? fail("Staged project manifest is invalid") : run("verifying-bundle-manifest", ["cat", "--", plan.stagingPath + "/bundle.json"]),
            "verifying-bundle-manifest": () => failed || !parseBundle(output, plan.projectId) ? fail("Staged bundle manifest is invalid") : run("checking-symlinks", ["find", plan.stagingPath, "-type", "l", "-print", "-quit"]),
            "checking-symlinks": () => failed || String(output).trim().length > 0 ? fail("Staged project contains a symbolic link") : run("checking-inventory", ["find", plan.stagingPath, "-type", "f", "-printf", "%P\\n"], 30000),
            "checking-inventory": () => failed || !Validation.acceptsInventory(context.completedDocument, output) ? fail("Staged project inventory does not match its manifest") : call("begin-file-verification"),
            "verifying-file-size": () => failed || !Validation.acceptsSize(context.activeFile, output) ? fail("Staged asset size does not match: " + context.activeFile.relativePath) : run("verifying-file-identity", ["sha256sum", "--", plan.stagingPath + "/" + context.activeFile.relativePath], context.transferTimeout(context.activeFile.sizeBytes)),
            "verifying-file-identity": () => failed || !Validation.acceptsIdentity(context.activeFile, output) ? fail("Staged asset identity does not match: " + context.activeFile.relativePath) : call("verify-next-file"),
            "publishing": () => failed ? fail("Project could not be published") : run("verifying-staging-moved", ["test", "!", "-e", plan.stagingPath]),
            "verifying-staging-moved": () => failed ? fail("Project name was claimed during publication") : run("verifying-published", ["test", "-d", plan.destinationPath, "-a", "-r", plan.destinationPath + "/project.json", "-a", "-r", plan.destinationPath + "/bundle.json"]),
            "verifying-published": () => failed ? fail("Published project could not be verified") : call("persist-completed"),
            "cleaning-staging": () => call("restore-or-finish")
        });
    const handler = handlers[stateKey];
    return handler ? handler() : fail("Unknown publication state: " + stateKey);
}
