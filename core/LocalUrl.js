.pragma library

function fromPath(value) {
    const path = String(value || "")
    if (path.length === 0 || path.startsWith("file:"))
        return path
    return "file://" + encodeURIComponent(path).replace(/%2F/gi, "/")
}
