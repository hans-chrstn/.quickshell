import QtQuick
import QtTest
import "../../services/island/IslandPresentationModel.js" as IslandPresentationModel

TestCase {
    name: "IslandPresentationModel"

    function test_enablesAndDisablesOneScreenWithoutMutatingInput() {
        const original = {
            "DP-1": true
        };
        const enabled = IslandPresentationModel.setZenEnabled(original, "HDMI-A-1", true);
        verify(enabled.accepted);
        verify(enabled.changed);
        verify(IslandPresentationModel.isZenEnabled(enabled.state, "DP-1"));
        verify(IslandPresentationModel.isZenEnabled(enabled.state, "HDMI-A-1"));
        verify(!IslandPresentationModel.isZenEnabled(original, "HDMI-A-1"));

        const disabled = IslandPresentationModel.setZenEnabled(enabled.state, "DP-1", false);
        verify(disabled.accepted);
        verify(disabled.changed);
        verify(!IslandPresentationModel.isZenEnabled(disabled.state, "DP-1"));
        verify(IslandPresentationModel.isZenEnabled(disabled.state, "HDMI-A-1"));
    }

    function test_repeatedRequestIsAcceptedWithoutChange() {
        const result = IslandPresentationModel.setZenEnabled({
            "DP-1": true
        }, "DP-1", true);
        verify(result.accepted);
        verify(!result.changed);
        compare(IslandPresentationModel.enabledScreenNames(result.state), ["DP-1"]);
    }

    function test_invalidInputsFailClosed() {
        verify(!IslandPresentationModel.setZenEnabled({}, "", true).accepted);
        verify(!IslandPresentationModel.setZenEnabled({}, "DP-1", "true").accepted);
    }

    function test_disconnectedScreensAreRemoved() {
        const retained = IslandPresentationModel.retainAvailable({
            "DP-1": true,
            "DP-3": true,
            "HDMI-A-1": true
        }, ["DP-3", "HDMI-A-1"]);
        compare(IslandPresentationModel.enabledScreenNames(retained), ["DP-3", "HDMI-A-1"]);
    }

    function test_namesAreBoundedToTrueEntriesAndSorted() {
        compare(IslandPresentationModel.enabledScreenNames({
            "DP-3": true,
            "DP-1": false,
            "HDMI-A-1": true
        }), ["DP-3", "HDMI-A-1"]);
    }
}
