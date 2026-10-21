import QtQuick
import QtTest
import "../../island/IslandInteraction.js" as IslandInteraction

TestCase {
    name: "IslandInteraction"

    function test_persistentCompactAttentionRetractsAfterPointerExit() {
        verify(!IslandInteraction.retainExpandedWithoutPointer(true, false));
    }

    function test_expandingAttentionRetainsExpandedPresentation() {
        verify(IslandInteraction.retainExpandedWithoutPointer(true, true));
    }

    function test_noAttentionNeverRetainsExpandedPresentation() {
        verify(!IslandInteraction.retainExpandedWithoutPointer(false, true));
        verify(!IslandInteraction.retainExpandedWithoutPointer(false, false));
    }
}
