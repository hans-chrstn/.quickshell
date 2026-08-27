import QtQuick
import qs.core

Item {
    id: root

    required property IslandModule module
    property bool expanded: false
    property real expansionProgress: 0

    readonly property QtObject moduleContext: QtObject {
        readonly property bool expanded: root.expanded
        readonly property real expansionProgress: root.expansionProgress
    }

    clip: true

    Loader {
        id: moduleLoader
        anchors.fill: parent
        active: root.module !== null
        sourceComponent: root.module?.view ?? null
        onLoaded: item.context = root.moduleContext
    }
}
