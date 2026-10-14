import QtQuick
import QtTest
import Quickshell
import qs.core
import qs.island
import qs.services.lifecycle

ShellRoot {
    id: harness

    property bool editorRequested: true
    property bool editorUsageActive: true
    property int editorConstructionCount: 0
    property int editorDestructionCount: 0
    property bool editorPresented: false
    property var editorInstance: null

    IslandModule {
        id: clockModule

        moduleId: "clock"
        active: true
        view: Component {
            Item {
                property QtObject context: null
            }
        }
    }

    IslandModule {
        id: editorModule

        moduleId: "editor"
        active: harness.editorRequested
        lifecycleAdaptiveEligible: true
        lifecycleUsageActive: harness.editorUsageActive
        lifecycleEstimatedCostUnits: 80
        lifecycleEvict: reason => {
            harness.editorRequested = false;
        }
        view: Component {
            Item {
                id: editorView

                property QtObject context: null
                readonly property bool presented: context?.presented ?? false

                onPresentedChanged: harness.editorPresented = presented
                Component.onCompleted: {
                    harness.editorConstructionCount += 1;
                    harness.editorInstance = editorView;
                    harness.editorPresented = presented;
                }
                Component.onDestruction: {
                    harness.editorDestructionCount += 1;
                    harness.editorPresented = false;
                }
            }
        }
    }

    Window {
        id: window

        width: 800
        height: 600
        visible: true

        IslandContentHost {
            id: host

            anchors.fill: parent
            module: editorModule
            modules: [clockModule, editorModule]
            presented: true
            expanded: true
            expansionProgress: 1
            screenName: "TEST"
            availableWidth: width
            availableHeight: height
        }

        TestCase {
            name: "IslandModuleRetention"
            when: window.visible

            function test_hiddenRetentionReuseAndEviction() {
                tryCompare(harness, "editorConstructionCount", 1);
                tryCompare(harness, "editorPresented", true);
                const retainedInstance = harness.editorInstance;
                verify(retainedInstance !== null);

                harness.editorUsageActive = false;
                host.module = clockModule;
                tryCompare(harness, "editorPresented", false);
                compare(harness.editorConstructionCount, 1);
                compare(harness.editorDestructionCount, 0);
                compare(harness.editorInstance, retainedInstance);

                const retainedRecord = LifecycleService.recordFor("island.module.TEST.editor");
                verify(retainedRecord.requested);
                verify(retainedRecord.loaded);
                verify(!retainedRecord.active);
                compare(retainedRecord.retentionReason, "inactive-retention");

                host.module = editorModule;
                harness.editorUsageActive = true;
                tryCompare(harness, "editorPresented", true);
                compare(harness.editorConstructionCount, 1);
                compare(harness.editorInstance, retainedInstance);

                harness.editorUsageActive = false;
                host.module = clockModule;
                LifecycleService.evictionRequested("island.module.TEST.editor", "test-budget");
                tryCompare(harness, "editorRequested", false);
                tryCompare(harness, "editorDestructionCount", 1);
                const evictedRecord = LifecycleService.recordFor("island.module.TEST.editor");
                verify(!evictedRecord.requested);
                verify(!evictedRecord.loaded);
            }
        }
    }
}
