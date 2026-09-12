import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperAutomationOverride.js" as Override

TestCase {
    name: "WallpaperAutomationOverride"

    function test_globalSuppressionSupersedesScreenState() {
        const source = { global: false, screens: { "DP-1": true } }
        const result = Override.suppressGlobal(source)
        verify(result.global)
        compare(Object.keys(result.screens).length, 0)
        verify(Override.suppressed(result, "DP-1"))
        verify(Override.suppressed(result, "HDMI-A-1"))
    }

    function test_screenSuppressionIsScopedAndResumable() {
        let result = Override.suppressScreen({}, "DP-3")
        verify(Override.suppressed(result, "DP-3"))
        verify(!Override.suppressed(result, "DP-1"))
        result = Override.resumeScreen(result, "DP-3")
        verify(!Override.suppressed(result, "DP-3"))
    }

    function test_resumeAllClearsEveryScope() {
        const result = Override.resumeAll({
            global: true,
            screens: { "DP-1": true, "DP-3": true }
        })
        verify(!result.global)
        compare(Object.keys(result.screens).length, 0)
    }

    function test_normalizationIsBoundedAndDefensive() {
        const screens = ({})
        for (let index = 0; index < Override.maximumScreens + 8; ++index)
            screens["screen-" + index] = true
        screens.empty = false
        const result = Override.normalize({ global: false, screens: screens })
        compare(Object.keys(result.screens).length, Override.maximumScreens)
        screens["screen-0"] = false
        verify(result.screens["screen-0"])
    }

    function test_screenMutationCannotEscapeGlobalSuppression() {
        const global = Override.suppressGlobal({})
        const changed = Override.suppressScreen(global, "DP-1")
        const resumed = Override.resumeScreen(global, "DP-1")
        verify(changed.global)
        verify(resumed.global)
        compare(Object.keys(changed.screens).length, 0)
        compare(Object.keys(resumed.screens).length, 0)
    }
}
