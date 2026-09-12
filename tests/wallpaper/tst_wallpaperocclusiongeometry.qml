import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperOcclusionGeometry.js" as Geometry

TestCase {
    name: "WallpaperOcclusionGeometry"

    readonly property var logicalScreen: ({
        x: 20, y: 30, width: 1280, height: 720, devicePixelRatio: 1.5
    })

    function compareBounds(actual, expected) {
        compare(actual.x, expected.x)
        compare(actual.y, expected.y)
        compare(actual.width, expected.width)
        compare(actual.height, expected.height)
    }

    function test_missingNativeDataFallsBackCompletely() {
        compareBounds(Geometry.monitorBounds({}, logicalScreen), {
            x: 20, y: 30, width: 1280, height: 720
        })
    }

    function test_partialNativeDataFallsBackPerField() {
        compareBounds(Geometry.monitorBounds({ x: 100, width: 1920, scale: 1.5 },
            logicalScreen), {
            x: 100, y: 30, width: 1280, height: 720
        })
    }

    function test_nativeScaleProducesLogicalBounds() {
        compareBounds(Geometry.monitorBounds({
            x: 100, y: 200, width: 2560, height: 1440,
            scale: 2, transform: 0
        }, logicalScreen), {
            x: 100, y: 200, width: 1280, height: 720
        })
    }

    function test_transformedNativeBoundsSwapLogicalAxes() {
        compareBounds(Geometry.monitorBounds({
            x: 0, y: 0, width: 1920, height: 1080,
            scale: 1, transform: 3
        }, logicalScreen), {
            x: 0, y: 0, width: 1080, height: 1920
        })
    }

    function test_invalidNativeValuesNeverPropagateNaN() {
        const bounds = Geometry.monitorBounds({
            x: "invalid", y: undefined, width: 0,
            height: "invalid", scale: 0
        }, logicalScreen)
        compareBounds(bounds, { x: 20, y: 30, width: 1280, height: 720 })
        verify(Number.isFinite(bounds.width))
        verify(Number.isFinite(bounds.height))
    }
}
