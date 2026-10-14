import QtQuick
import QtTest
import "../../editor/EditorShortcutPolicy.js" as ShortcutPolicy

TestCase {
    name: "EditorShortcutPolicy"

    function test_editorBindings() {
        const cases = [[Qt.Key_A, Qt.ControlModifier, "select-all"], [Qt.Key_Delete, Qt.NoModifier, "remove-selection"], [Qt.Key_Backspace, Qt.NoModifier, "remove-selection"], [Qt.Key_Home, Qt.NoModifier, "timeline-start"], [Qt.Key_End, Qt.NoModifier, "timeline-end"], [Qt.Key_PageUp, Qt.NoModifier, "timeline-back"], [Qt.Key_PageDown, Qt.NoModifier, "timeline-forward"], [Qt.Key_Space, Qt.NoModifier, "toggle-playback"], [Qt.Key_Z, Qt.ControlModifier, "undo"], [Qt.Key_Z, Qt.ControlModifier | Qt.ShiftModifier, "redo"], [Qt.Key_Y, Qt.ControlModifier, "redo"]];
        for (const entry of cases)
            compare(ShortcutPolicy.action(entry[0], entry[1]), entry[2]);
    }

    function test_unboundKeysRemainAvailableToFocusedControls() {
        compare(ShortcutPolicy.action(Qt.Key_A, Qt.NoModifier), "");
        compare(ShortcutPolicy.action(Qt.Key_X, Qt.ControlModifier), "");
        compare(ShortcutPolicy.action(Qt.Key_Return, Qt.NoModifier), "");
    }
}
