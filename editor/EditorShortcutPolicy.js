.pragma library

function action(key, modifiers) {
    const control = (modifiers & Qt.ControlModifier) !== 0;
    const shift = (modifiers & Qt.ShiftModifier) !== 0;
    if (control && key === Qt.Key_A)
        return "select-all";
    if (key === Qt.Key_Delete || key === Qt.Key_Backspace)
        return "remove-selection";
    if (key === Qt.Key_Home)
        return "timeline-start";
    if (key === Qt.Key_End)
        return "timeline-end";
    if (key === Qt.Key_PageUp)
        return "timeline-back";
    if (key === Qt.Key_PageDown)
        return "timeline-forward";
    if (key === Qt.Key_Space)
        return "toggle-playback";
    if (control && key === Qt.Key_Z)
        return shift ? "redo" : "undo";
    if (control && key === Qt.Key_Y)
        return "redo";
    return "";
}
