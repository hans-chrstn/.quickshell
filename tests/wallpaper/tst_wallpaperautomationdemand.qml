import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperAutomationDemand.js" as Demand

TestCase {
    name: "WallpaperAutomationDemand"

    function test_notReadyNeverActivates() {
        verify(!Demand.requested(false, "playlist", { "DP-1": "other" }, [
            { enabled: true }
        ]))
    }

    function test_emptyStateIsDormant() {
        verify(!Demand.requested(true, "", {}, []))
    }

    function test_globalOrScreenTargetActivates() {
        verify(Demand.requested(true, "playlist", {}, []))
        verify(Demand.requested(true, "", { "DP-1": "playlist" }, []))
    }

    function test_onlyEnabledRulesActivate() {
        verify(!Demand.requested(true, "", {}, [{ enabled: false }]))
        verify(Demand.requested(true, "", {}, [
            { enabled: false }, { enabled: true }
        ]))
    }
}
