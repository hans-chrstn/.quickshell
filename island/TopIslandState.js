.pragma library

const routes = ["media", "notifications", "launcher"];

function normalize(state) {
    const phase = String(state?.phase || "hidden");
    return {
        phase: phase === "hidden" || phase === "compact" || routes.includes(phase) ? phase : "hidden",
        expanded: routes.includes(phase) && state?.expanded === true
    };
}

function reduce(state, event) {
    const current = normalize(state);
    const kind = String(event?.kind || "");
    if (kind === "wake")
        return current.phase === "hidden" ? {
            phase: "compact",
            expanded: false
        } : current;
    if (kind === "hide" || kind === "outside")
        return {
            phase: "hidden",
            expanded: false
        };
    if (kind === "open-route" && (event?.phase === "compact" || routes.includes(String(event?.phase || ""))))
        return {
            phase: event.phase,
            expanded: event.phase !== "compact" && event?.expanded === true
        };
    if (kind === "open-launcher" || kind === "type" && (current.phase === "compact" || current.phase === "launcher"))
        return {
            phase: "launcher",
            expanded: false
        };
    if (kind === "launcher-closed" && current.phase === "launcher")
        return {
            phase: "compact",
            expanded: false
        };
    if (kind === "left" && current.phase === "compact")
        return {
            phase: "media",
            expanded: false
        };
    if (kind === "right" && current.phase === "compact")
        return {
            phase: "notifications",
            expanded: false
        };
    if (kind === "right" && routes.includes(current.phase))
        return {
            phase: current.phase,
            expanded: !current.expanded
        };
    if (kind === "escape") {
        if (current.expanded)
            return {
                phase: current.phase,
                expanded: false
            };
        if (routes.includes(current.phase))
            return {
                phase: "compact",
                expanded: false
            };
        return {
            phase: "hidden",
            expanded: false
        };
    }
    return current;
}
