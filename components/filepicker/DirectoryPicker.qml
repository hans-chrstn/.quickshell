import QtQuick
import qs.components.filepicker

Item {
    id: root

    property alias initialPath: picker.initialPath
    property alias currentPath: picker.currentPath
    property alias showHidden: picker.showHidden
    signal accepted(string path)
    signal canceled()

    FilePicker {
        id: picker
        anchors.fill: parent
        mode: "directory"
        onAccepted: paths => root.accepted(paths[0] || "/")
        onCanceled: root.canceled()
    }
}
