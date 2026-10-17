.pragma library

var actionTypes = ["set-wallpaper", "play-media", "set-property", "show-notification"];
var maximumActions = 16;

function normalizeAction(value) {
    const source = value || ({});
    const type = String(source.type || "");
    if (actionTypes.indexOf(type) < 0)
        return {
            accepted: false,
            error: "Unsupported trigger action"
        };
    const id = String(source.id || "").trim().slice(0, 96);
    if (id.length === 0)
        return {
            accepted: false,
            error: "Trigger action id is required"
        };
    return {
        accepted: true,
        error: "",
        action: {
            id: id,
            type: type,
            target: String(source.target || "").trim().slice(0, 512),
            value: source.value === undefined ? null : source.value
        }
    };
}

function normalizeActions(values) {
    if (!Array.isArray(values))
        return {
            accepted: false,
            error: "Trigger actions must be an array"
        };
    if (values.length > maximumActions)
        return {
            accepted: false,
            error: "Trigger action limit exceeded"
        };
    const actions = [];
    const ids = ({});
    for (const value of values) {
        const result = normalizeAction(value);
        if (!result.accepted)
            return result;
        if (ids[result.action.id])
            return {
                accepted: false,
                error: "Trigger action ids must be unique"
            };
        ids[result.action.id] = true;
        actions.push(result.action);
    }
    return {
        accepted: true,
        error: "",
        actions: actions
    };
}

function changeActions(values, operation, actionId, value) {
    const current = normalizeActions(values);
    if (!current.accepted)
        return current;
    if (["add", "remove", "update"].indexOf(operation) < 0)
        return {
            accepted: false,
            error: "Unsupported trigger action operation"
        };
    const actions = current.actions.slice();
    const index = actions.findIndex(action => action.id === String(actionId || ""));
    if (operation === "add") {
        const added = normalizeAction(value);
        if (!added.accepted)
            return added;
        if (actions.length >= maximumActions || actions.some(action => action.id === added.action.id))
            return {
                accepted: false,
                error: "Trigger action limit or duplicate id"
            };
        actions.push(added.action);
    } else if (index < 0) {
        return {
            accepted: false,
            error: "Trigger action was not found"
        };
    } else if (operation === "remove") {
        actions.splice(index, 1);
    } else if (operation === "update") {
        const updated = normalizeAction(Object.assign({}, actions[index], value || {}, {
            id: actions[index].id
        }));
        if (!updated.accepted)
            return updated;
        actions[index] = updated.action;
    }
    return {
        accepted: true,
        error: "",
        actions: actions
    };
}

function addAction(values, value) {
    return changeActions(values, "add", "", value);
}
function updateAction(values, actionId, value) {
    return changeActions(values, "update", actionId, value);
}
function removeAction(values, actionId) {
    return changeActions(values, "remove", actionId, null);
}
