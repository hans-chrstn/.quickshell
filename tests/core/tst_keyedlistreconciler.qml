import QtQuick
import QtTest
import "../../components/models/KeyedListReconciler.js" as KeyedListReconciler

TestCase {
    id: testCase

    name: "KeyedListReconciler"
    width: 320
    height: 180
    when: windowShown

    ListModel {
        id: stableModel

        dynamicRoles: true
    }

    ListView {
        id: list

        anchors.fill: parent
        model: stableModel

        delegate: Item {
            required property string key
            required property var record
            width: list.width
            height: 50
        }
    }

    function init() {
        stableModel.clear();
        wait(0);
    }

    function test_sameKeysUpdateWithoutReplacingDelegates() {
        KeyedListReconciler.reconcile(stableModel, [
            {
                sessionId: "stream-a",
                volume: 0.2
            },
            {
                sessionId: "stream-b",
                volume: 0.4
            }
        ], "sessionId", "stream:");
        list.forceLayout();
        tryVerify(() => list.itemAtIndex(0) !== null && list.itemAtIndex(1) !== null);
        const firstDelegate = list.itemAtIndex(0);
        const secondDelegate = list.itemAtIndex(1);
        verify(firstDelegate !== null);
        verify(secondDelegate !== null);

        KeyedListReconciler.reconcile(stableModel, [
            {
                sessionId: "stream-a",
                volume: 0.7
            },
            {
                sessionId: "stream-b",
                volume: 0.8
            }
        ], "sessionId", "stream:");
        list.forceLayout();
        wait(0);

        compare(list.itemAtIndex(0), firstDelegate);
        compare(list.itemAtIndex(1), secondDelegate);
        compare(list.itemAtIndex(0).record.volume, 0.7);
        compare(list.itemAtIndex(1).record.volume, 0.8);
    }

    function test_reorderAndRemovalFollowStableKeys() {
        KeyedListReconciler.reconcile(stableModel, [
            {
                sessionId: "stream-a"
            },
            {
                sessionId: "stream-b"
            },
            {
                sessionId: "stream-c"
            }
        ], "sessionId", "stream:");
        KeyedListReconciler.reconcile(stableModel, [
            {
                sessionId: "stream-c"
            },
            {
                sessionId: "stream-a"
            }
        ], "sessionId", "stream:");

        compare(stableModel.count, 2);
        compare(stableModel.get(0).key, "stream-c");
        compare(stableModel.get(1).key, "stream-a");
    }
}
