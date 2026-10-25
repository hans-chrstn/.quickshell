pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool editorActive: editorOpen || editorClosing
    property bool editorOpen: false
    property bool editorClosing: false

    function setEditorState(opened, closing) {
        editorOpen = Boolean(opened)
        editorClosing = Boolean(closing)
    }
}
