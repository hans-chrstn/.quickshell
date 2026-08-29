import QtQuick
import qs.components.lifecycle
import qs.core

Item {
    id: root

    required property IslandModule module
    property bool expanded: false
    property real expansionProgress: 0
    property string screenName: ""

    readonly property QtObject moduleContext: QtObject {
        readonly property bool expanded: root.expanded
        readonly property real expansionProgress: root.expansionProgress
        readonly property string screenName: root.screenName
    }

    clip: true

    LifecycleLoader {
        id: moduleLoader
        anchors.fill: parent
        resourceId: "island.module." + root.screenName + "."
            + (root.module?.moduleId ?? "none")
        owner: "island.content." + root.screenName
        restorationSource: "ModuleRegistry and feature singleton service"
        classification: "active-only"
        requestedActive: root.module !== null
        retentionReason: requestedActive ? "selected-module" : ""
        evictionReason: requestedActive ? "" : "no-active-module"
        sourceComponent: root.module?.view ?? null
        readonly property real revealProgress: {
            if (!root.module?.revealWithExpansion)
                return 1
            const span = root.module.revealEnd - root.module.revealStart
            if (span <= 0)
                return root.expansionProgress >= root.module.revealEnd ? 1 : 0
            return Math.max(0, Math.min(1,
                (root.expansionProgress - root.module.revealStart) / span))
        }
        opacity: revealProgress
        transform: Translate {
            y: (1 - moduleLoader.revealProgress)
                * root.module.revealOffsetY
        }
        onInstanceLoaded: function(item) {
            item.context = root.moduleContext
        }
    }
}
