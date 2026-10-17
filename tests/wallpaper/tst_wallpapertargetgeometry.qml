import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperTargetGeometry.js" as Geometry

TestCase {
    name: "WallpaperTargetGeometry"

    readonly property var screens: [
        { name: "Internal", width: 1920, height: 1080,
            devicePixelRatio: 1 },
        { name: "Scaled", width: 1280, height: 720,
            devicePixelRatio: 2 }
    ]

    function test_namedDisplayUsesPhysicalPixels() {
        const result = Geometry.physicalDimensions(screens, "Scaled")
        verify(result.available)
        compare(result.width, 2560)
        compare(result.height, 1440)
        compare(result.matches, 1)
    }

    function test_allDisplaysUsesLargestPhysicalEnvelope() {
        const result = Geometry.physicalDimensions(screens, "All Displays")
        verify(result.available)
        compare(result.width, 2560)
        compare(result.height, 1440)
        compare(result.matches, 2)
    }

    function test_disconnectedDisplayIsUnavailable() {
        const result = Geometry.physicalDimensions(screens, "Missing")
        verify(!result.available)
        compare(result.width, 0)
        compare(result.height, 0)
        compare(result.error, "The selected display is not connected")
    }

    function test_emptyTopologyDoesNotInvent1080p() {
        const result = Geometry.physicalDimensions([], "All Displays")
        verify(!result.available)
        compare(result.width, 0)
        compare(result.height, 0)
        compare(result.error, "No connected displays are available")
    }

    function test_invalidTargetIsRejected() {
        const result = Geometry.physicalDimensions(screens, "")
        verify(!result.available)
        compare(result.error, "A wallpaper target is required")
    }
}
