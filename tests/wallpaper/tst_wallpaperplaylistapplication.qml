import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperPlaylistApplication.js" as Application

TestCase {
    name: "WallpaperPlaylistApplication"

    function test_keepsOnlyReadyNamedPaths() {
        const paths = Application.pathsForPlans({
            "DP-1": { state: "ready", path: "/wall/a.png" },
            "DP-2": { state: "dormant", path: "/wall/b.png" },
            "": { state: "ready", path: "/wall/c.png" },
            "DP-3": { state: "ready", path: "" }
        })
        compare(JSON.stringify(paths),
            JSON.stringify({ "DP-1": "/wall/a.png" }))
    }

    function test_returnsDefensiveResult() {
        const plans = {
            "DP-1": { state: "ready", path: "/wall/a.png" }
        }
        const paths = Application.pathsForPlans(plans)
        paths["DP-1"] = "/changed.png"
        compare(plans["DP-1"].path, "/wall/a.png")
    }

    function test_boundsOutputs() {
        const plans = ({})
        for (let index = 0; index < 40; ++index)
            plans["DP-" + index] = {
                state: "ready", path: "/wall/" + index + ".png"
            }
        compare(Object.keys(Application.pathsForPlans(plans)).length, 32)
        compare(Object.keys(Application.pathsForPlans(plans, 2)).length, 2)
    }

    function test_handlesUnavailableInput() {
        compare(Object.keys(Application.pathsForPlans(null)).length, 0)
        compare(Object.keys(Application.pathsForPlans("invalid")).length, 0)
    }
}
