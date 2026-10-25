.pragma library

function publicationDocument(bundleDocument, projectDocument) {
    const bundle = JSON.parse(JSON.stringify(bundleDocument || ({})));
    const assets = projectDocument?.project?.assets;
    if (!bundle.workspace || !Array.isArray(bundle.workspace.files) || !Array.isArray(assets))
        return null;
    const retainedIds = ({});
    for (const asset of assets)
        retainedIds[String(asset.id || "")] = true;
    bundle.workspace.files = bundle.workspace.files.filter(file => retainedIds[String(file.assetId || "")] === true);
    return bundle;
}

function excludedPaths(sourceDocument, publicationDocument) {
    const retained = ({});
    for (const file of publicationDocument?.workspace?.files || [])
        retained[String(file.relativePath || "")] = true;
    return (sourceDocument?.workspace?.files || []).map(file => String(file.relativePath || "")).filter(path => path.length > 0 && !retained[path]);
}

function expectedInventory(bundleDocument) {
    const expected = ({
            "bundle.json": true,
            "project.json": true
        });
    const files = bundleDocument?.workspace?.files || [];
    for (const file of files)
        expected[file.relativePath] = true;
    return expected;
}

function acceptsInventory(bundleDocument, output) {
    const expected = expectedInventory(bundleDocument);
    const actual = String(output || "").split("\n").map(path => path.trim()).filter(path => path.length > 0);
    if (actual.length !== Object.keys(expected).length)
        return false;
    const seen = ({});
    for (const path of actual) {
        if (!expected[path] || seen[path])
            return false;
        seen[path] = true;
    }
    return Object.keys(expected).every(path => seen[path] === true);
}

function acceptsSize(file, output) {
    return Number(output) === Number(file?.sizeBytes);
}

function acceptsIdentity(file, output) {
    const match = String(output || "").match(/^([0-9a-fA-F]{64})(?:\s|$)/);
    return match !== null && file?.identity.toLowerCase() === "sha256:" + match[1].toLowerCase();
}
