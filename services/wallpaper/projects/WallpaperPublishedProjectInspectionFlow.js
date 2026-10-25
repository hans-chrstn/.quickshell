.pragma library

function run(state, command, timeoutMs) {
    return {
        kind: "run",
        state: state,
        command: command,
        timeoutMs: timeoutMs || 10000
    };
}

function call(name) {
    return {
        kind: "call",
        name: name
    };
}

function fail(message) {
    return {
        kind: "fail",
        message: message
    };
}

function next(state, exitCode, output, context) {
    const key = String(state || "");
    const failed = exitCode !== 0;
    const rootPath = context.rootPath;
    const handlers = ({
            "checking-root": () => failed ? fail("Project folder or required manifests are unavailable") : run("reading-project", ["cat", "--", rootPath + "/project.json"]),
            "reading-project": () => failed ? fail("Project manifest could not be read") : call("parse-project"),
            "reading-bundle": () => failed ? fail("Bundle manifest could not be read") : call("parse-bundle"),
            "checking-symlinks": () => failed || String(output || "").trim().length > 0 ? fail("Project folder contains a symbolic link") : run("scanning-inventory", ["find", rootPath, "-type", "f", "-printf", "%P\\n"], 30000),
            "scanning-inventory": () => failed ? fail("Project file inventory could not be read") : call("prepare-verification"),
            "verifying-size": () => failed ? fail("Project file size could not be read") : call("accept-size"),
            "verifying-identity": () => failed ? fail("Project file identity could not be read") : call("accept-identity")
        });
    const handler = handlers[key];
    return handler ? handler() : fail("Unknown project inspection state: " + key);
}
