import QtQuick
import QtTest
import "../../core" as Core

TestCase {
    id: testCase
    name: "ModuleRegistry"

    Core.ModuleRegistry {
        id: registry
        modules: [
            Core.IslandModule {
                id: clock
                moduleId: "clock"
                active: true
                priority: 0
            },
            Core.IslandModule {
                id: closingEditor
                moduleId: "editor"
                active: true
                attention: false
                priority: 95
            },
            Core.IslandModule {
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
