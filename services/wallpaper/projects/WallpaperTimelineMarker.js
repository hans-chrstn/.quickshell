.pragma library
.import "WallpaperProjectModel.js" as ProjectModel
.import "WallpaperTriggerAction.js" as TriggerAction

var triggerTypes = ["manual", "time", "date", "weather", "battery", "workspace", "application", "window", "media", "session", "monitor"];
var missedEventPolicies = ["skip", "fire-on-resume"];
var loopPolicies = ["once", "repeat"];

function failure(message) {
    return {
        accepted: false,
        error: String(message || "Marker edit failed"),
        document: null
    };
}

function success(document) {
    return {
        accepted: true,
        error: "",
        document: document
    };
}

function projectOf(document) {
    return document && document.project && Array.isArray(document.project.markers) ? document.project : null;
}

function markerIndex(project, markerId) {
    return project.markers.findIndex(marker => marker.id === markerId);
}

function copyWithMarkers(document, markers) {
    return Object.assign({}, document, {
        project: Object.assign({}, document.project, {
            markers: markers
        })
    });
}

function normalizedId(value) {
    return String(value || "").trim().slice(0, 96);
}

function normalizedName(value) {
    return String(value || "").trim().slice(0, 160);
}

function normalizedTime(value, durationMs) {
    const duration = Math.max(0, Number(durationMs) || 0);
    const time = Number(value);
    if (!Number.isFinite(time))
        return 0;
    return Math.max(0, Math.min(ProjectModel.maximumProjectDurationMs, Math.min(duration, Math.round(time))));
}

function normalizedPriority(value) {
    const priority = Number(value);
    return Number.isFinite(priority) ? Math.max(-100, Math.min(100, Math.round(priority))) : 0;
}

function normalizedCooldown(value) {
    const cooldown = Number(value);
    return Number.isFinite(cooldown) ? Math.max(0, Math.min(86400000, Math.round(cooldown))) : 1000;
}

function normalizedDebounce(value) {
    const debounce = Number(value);
    return Number.isFinite(debounce) ? Math.max(0, Math.min(60000, Math.round(debounce))) : 0;
}

function normalizedPolicy(value, allowed, fallback) {
    const policy = String(value || "");
    return allowed.indexOf(policy) >= 0 ? policy : fallback;
}

function add(document, markerId, name, timeMs, triggerType, enabled) {
    const project = projectOf(document);
    if (!project)
        return failure("Canonical project is required");
    if (project.markers.length >= ProjectModel.maximumMarkers)
        return failure("Marker limit exceeded");
    const id = normalizedId(markerId);
    if (id.length === 0 || markerIndex(project, id) >= 0)
        return failure("Marker id must be unique");
    const label = normalizedName(name);
    if (label.length === 0)
        return failure("Marker name is required");
    const type = String(triggerType || "manual");
    if (triggerTypes.indexOf(type) < 0)
        return failure("Unsupported marker trigger");
    const marker = {
        id: id,
        name: label,
        timeMs: normalizedTime(timeMs, project.durationMs),
        triggerType: type,
        enabled: enabled !== false,
        priority: 0,
        exclusive: false,
        cooldownMs: 1000,
        debounceMs: 0,
        missedEvent: "skip",
        loopPolicy: "once",
        actions: []
    };
    return success(copyWithMarkers(document, project.markers.concat([marker])));
}

function update(document, markerId, changes) {
    const project = projectOf(document);
    if (!project)
        return failure("Canonical project is required");
    const id = normalizedId(markerId);
    const index = markerIndex(project, id);
    if (index < 0)
        return failure("Timeline marker was not found");
    const current = project.markers[index];
    const next = Object.assign({}, current);
    if (changes && changes.name !== undefined) {
        next.name = normalizedName(changes.name);
        if (next.name.length === 0)
            return failure("Marker name is required");
    }
    if (changes && changes.timeMs !== undefined)
        next.timeMs = normalizedTime(changes.timeMs, project.durationMs);
    if (changes && changes.triggerType !== undefined) {
        next.triggerType = String(changes.triggerType || "");
        if (triggerTypes.indexOf(next.triggerType) < 0)
            return failure("Unsupported marker trigger");
    }
    if (changes && changes.enabled !== undefined)
        next.enabled = changes.enabled === true;
    if (changes && changes.priority !== undefined)
        next.priority = normalizedPriority(changes.priority);
    if (changes && changes.exclusive !== undefined)
        next.exclusive = changes.exclusive === true;
    if (changes && changes.cooldownMs !== undefined)
        next.cooldownMs = normalizedCooldown(changes.cooldownMs);
    if (changes && changes.debounceMs !== undefined)
        next.debounceMs = normalizedDebounce(changes.debounceMs);
    if (changes && changes.missedEvent !== undefined)
        next.missedEvent = normalizedPolicy(changes.missedEvent, missedEventPolicies, "skip");
    if (changes && changes.loopPolicy !== undefined)
        next.loopPolicy = normalizedPolicy(changes.loopPolicy, loopPolicies, "once");
    if (changes && changes.actions !== undefined) {
        const actionResult = TriggerAction.normalizeActions(changes.actions);
        if (!actionResult.accepted)
            return failure(actionResult.error);
        next.actions = actionResult.actions;
    }
    const markers = project.markers.slice();
    markers[index] = next;
    return success(copyWithMarkers(document, markers));
}

function remove(document, markerId) {
    const project = projectOf(document);
    if (!project)
        return failure("Canonical project is required");
    const index = markerIndex(project, normalizedId(markerId));
    if (index < 0)
        return failure("Timeline marker was not found");
    const markers = project.markers.slice();
    markers.splice(index, 1);
    return success(copyWithMarkers(document, markers));
}
