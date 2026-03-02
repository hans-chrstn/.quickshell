import QtQuick
import qs.core
import qs.ui.shared

Item {
    id: root

    property var logic
    anchors.fill: parent
    z: 100

    NotesSaveAsOverlay {
        logic: root.logic
    }

    NotesDeleteOverlay {
        logic: root.logic
    }
}
