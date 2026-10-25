import QtQuick
import qs.components.lifecycle
import qs.core

Item {
    id: root

    required property IslandModule module
    required property list<IslandModule> modules
    property bool presented: false
    property bool expanded: false
    property real expansionProgress: 0
    property bool returningToClock: false
    property string screenName: ""
    property real availableWidth: 0
    property real availableHeight: 0
    readonly property Item selectedSlot: {
        const selected = root.module;
        const count = moduleSlots.count;
        for (let index = 0; index < count; ++index) {
            const slot = moduleSlots.itemAt(index);
            if (slot?.moduleSpec === selected)
                return slot;
        }
        return null;
    }
    readonly property real collapsedImplicitWidth: Number(selectedSlot?.collapsedImplicitWidth) || 0
    readonly property real collapsedImplicitHeight: Number(selectedSlot?.collapsedImplicitHeight) || 0
    readonly property real expandedImplicitWidth: Number(selectedSlot?.expandedImplicitWidth) || 0
    readonly property real expandedImplicitHeight: Number(selectedSlot?.expandedImplicitHeight) || 0

    clip: true

    Repeater {
        id: moduleSlots
        model: root.modules

        delegate: Item {
            id: moduleSlot

            required property var modelData
            readonly property IslandModule moduleSpec: modelData
            readonly property bool selected: root.module === moduleSpec
            readonly property real collapsedImplicitWidth: Number(moduleLoader.item?.collapsedImplicitWidth) || 0
            readonly property real collapsedImplicitHeight: Number(moduleLoader.item?.collapsedImplicitHeight) || 0
            readonly property real expandedImplicitWidth: Number(moduleLoader.item?.expandedImplicitWidth) || 0
            readonly property real expandedImplicitHeight: Number(moduleLoader.item?.expandedImplicitHeight) || 0
            readonly property QtObject moduleContext: QtObject {
                readonly property bool presented: moduleSlot.selected && root.presented
                readonly property bool expanded: moduleSlot.selected && root.expanded
                readonly property real expansionProgress: moduleSlot.selected ? root.expansionProgress : 0
                readonly property string screenName: root.screenName
                readonly property real availableWidth: root.availableWidth
                readonly property real availableHeight: root.availableHeight
            }

            anchors.fill: parent
            visible: selected && moduleLoader.loaded
            z: selected ? 1 : 0

            LifecycleLoader {
                id: moduleLoader

                anchors.fill: parent
                resourceId: "island.module." + root.screenName + "." + (moduleSlot.moduleSpec?.moduleId ?? "none")
                owner: "island.content." + root.screenName
                restorationSource: moduleSlot.moduleSpec?.lifecycleRestorationSource ?? ""
                classification: moduleSlot.moduleSpec?.lifecycleClassification ?? "active-only"
                requestedActive: moduleSlot.moduleSpec?.active ?? false
                adaptiveEligible: moduleSlot.moduleSpec?.lifecycleAdaptiveEligible ?? false
                usageActive: requestedActive && (moduleSlot.moduleSpec?.lifecycleUsageActive ?? moduleSlot.selected)
                estimatedCostUnits: moduleSlot.moduleSpec?.lifecycleEstimatedCostUnits ?? 0
                basePriority: moduleSlot.moduleSpec?.lifecycleBasePriority ?? 0
                retentionReason: requestedActive ? (usageActive ? "active-module" : "inactive-retention") : ""
                evictionReason: requestedActive ? "" : "module-not-requested"
                sourceComponent: moduleSlot.moduleSpec?.view ?? null
                readonly property real revealProgress: {
                    if (!moduleSlot.moduleSpec?.revealWithExpansion)
                        return 1;
                    const span = moduleSlot.moduleSpec.revealEnd - moduleSlot.moduleSpec.revealStart;
                    if (span <= 0)
                        return root.expansionProgress >= moduleSlot.moduleSpec.revealEnd ? 1 : 0;
                    return Math.max(0, Math.min(1, (root.expansionProgress - moduleSlot.moduleSpec.revealStart) / span));
                }
                opacity: !moduleSlot.selected ? 0 : root.returningToClock ? root.expansionProgress : revealProgress
                onInstanceLoaded: function (item) {
                    item.context = moduleSlot.moduleContext;
                }
                onAdaptiveEvictionRequested: function (reason) {
                    if (moduleSlot.moduleSpec?.lifecycleEvict)
                        moduleSlot.moduleSpec.lifecycleEvict(reason);
                }
            }
        }
    }
}
