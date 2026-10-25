import QtQuick
import QtTest
import "../../core" as Core

TestCase {
    id: testCase
    name: "ModuleRegistry"

    component TestModule: Core.IslandModule {
        collapsedWidth: 170
        collapsedHeight: 34
        expandedWidth: 440
        expandedHeight: 154
        collapsedSize: Core.IslandSizePolicy {
            minimumWidth: 170
            preferredWidth: 170
            maximumWidth: 170
            minimumHeight: 34
            preferredHeight: 34
            maximumHeight: 34
        }
        expandedSize: Core.IslandSizePolicy {
            minimumWidth: 440
            preferredWidth: 440
            maximumWidth: 440
            minimumHeight: 154
            preferredHeight: 154
            maximumHeight: 154
        }
    }

    Core.ModuleRegistry {
        id: registry
        modules: [
            TestModule {
                id: clock
                moduleId: "clock"
                active: true
                priority: 0
            },
            TestModule {
                id: closingEditor
                moduleId: "editor"
                active: true
                attention: false
                priority: 95
            },
            TestModule {
                id: notification
                moduleId: "notification"
                active: true
                attention: true
                priority: 60
            }
        ]
    }

    function test_attentiveFallbackIsIndependentFromCurrent() {
        compare(registry.current, closingEditor);
        compare(registry.attentive, notification);
        verify(registry.attentionRequested);
    }

    function test_currentChangesAfterClosingModuleDeactivates() {
        closingEditor.active = false;
        compare(registry.current, notification);
        compare(registry.attentive, notification);
        closingEditor.active = true;
    }

    function test_noAttentiveModuleMeansNoAttention() {
        notification.attention = false;
        compare(registry.current, closingEditor);
        compare(registry.attentive, null);
        verify(!registry.attentionRequested);
        notification.attention = true;
    }
}
