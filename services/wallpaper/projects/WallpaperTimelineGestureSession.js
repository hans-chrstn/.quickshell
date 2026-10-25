.pragma library
.import "WallpaperTimelineGesture.js" as Gesture

function idle(completedGestureId) {
    return {
        active: false,
        gesture: null,
        preview: null,
        completedGestureId: String(completedGestureId || "")
    }
}

function failure(state, message) {
    return { accepted: false, error: message, state: state, command: null }
}

function begin(state, gesture) {
    const current = state || idle("")
    if (current.active)
        return failure(current, "Another timeline gesture is active")
    if (!gesture || String(gesture.id || "").length === 0)
        return failure(current, "Timeline gesture is invalid")
    if (gesture.id === current.completedGestureId)
        return failure(current, "Timeline gesture was already completed")
    return {
        accepted: true,
        error: "",
        command: null,
        state: {
            active: true,
            gesture: gesture,
            preview: null,
            completedGestureId: current.completedGestureId
        }
    }
}

function update(state, preview) {
    if (!state?.active || !state.gesture)
        return failure(state || idle(""), "No timeline gesture is active")
    const value = preview?.preview || preview
    if (!value || value.gestureId !== state.gesture.id)
        return failure(state, "Gesture preview does not match")
    return {
        accepted: true,
        error: "",
        command: null,
        state: Object.assign({}, state, { preview: value })
    }
}

function finish(state) {
    if (!state?.active || !state.gesture || !state.preview)
        return failure(state || idle(""), "Gesture has no current preview")
    const finished = Gesture.finish(state.gesture, state.preview)
    if (!finished.accepted)
        return failure(state, finished.error)
    return {
        accepted: true,
        error: "",
        command: finished.command,
        state: idle(state.gesture.id)
    }
}

function cancel(state) {
    if (!state?.active)
        return { accepted: true, error: "", command: null,
            state: state || idle("") }
    return { accepted: true, error: "", command: null,
        state: idle(state.completedGestureId) }
}
