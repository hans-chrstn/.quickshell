import QtQuick
import QtTest
import "../../core/IslandSizing.js" as IslandSizing

TestCase {
    name: "IslandSizing"

    function test_declaredSizePassesThrough() {
        const result = IslandSizing.resolve({
            source: "declared",
            minimumWidth: 220,
            preferredWidth: 220,
            maximumWidth: 220,
            minimumHeight: 34,
            preferredHeight: 34,
            maximumHeight: 34
        }, {
            availableWidth: 1920,
            availableHeight: 1080
        })

        compare(result.source, "declared")
        compare(result.resolvedWidth, 220)
        compare(result.resolvedHeight, 34)
        verify(!result.widthConstrained)
        verify(!result.heightConstrained)
    }

    function test_intrinsicPreferenceIsConstrainedByMonitor() {
        const result = IslandSizing.resolve({
            source: "intrinsic",
            minimumWidth: 420,
            preferredWidth: 780,
            maximumWidth: 900,
            minimumHeight: 120,
            preferredHeight: 460,
            maximumHeight: 600
        }, {
            availableWidth: 700,
            availableHeight: 400
        })

        compare(result.source, "intrinsic")
        compare(result.requestedWidth, 780)
        compare(result.resolvedWidth, 700)
        compare(result.resolvedHeight, 400)
        verify(result.widthConstrained)
        verify(result.heightConstrained)
        verify(!result.widthBelowMinimum)
        verify(!result.heightBelowMinimum)
    }

    function test_intrinsicMeasurementReplacesPreferredSize() {
        const result = IslandSizing.resolve({
            source: "intrinsic",
            minimumWidth: 220,
            preferredWidth: 330,
            maximumWidth: 520,
            minimumHeight: 34,
            preferredHeight: 88,
            maximumHeight: 220
        }, {
            availableWidth: 1920,
            availableHeight: 1080
        }, {}, {
            width: 286,
            height: 66
        })

        verify(result.measurementReady)
        compare(result.requestedWidth, 286)
        compare(result.requestedHeight, 66)
        compare(result.resolvedWidth, 286)
        compare(result.resolvedHeight, 66)
    }

    function test_missingIntrinsicMeasurementUsesFallbackPolicy() {
        const result = IslandSizing.resolve({
            source: "intrinsic",
            minimumWidth: 220,
            preferredWidth: 330,
            maximumWidth: 520,
            minimumHeight: 34,
            preferredHeight: 88,
            maximumHeight: 220
        }, {
            availableWidth: 1920,
            availableHeight: 1080
        })

        verify(!result.measurementReady)
        compare(result.resolvedWidth, 330)
        compare(result.resolvedHeight, 88)
    }

    function test_unavoidableMinimumViolationIsExplicit() {
        const result = IslandSizing.resolve({
            minimumWidth: 600,
            preferredWidth: 720,
            maximumWidth: 900,
            minimumHeight: 300,
            preferredHeight: 360,
            maximumHeight: 500
        }, {
            availableWidth: 500,
            availableHeight: 240
        })

        compare(result.resolvedWidth, 500)
        compare(result.resolvedHeight, 240)
        verify(result.widthBelowMinimum)
        verify(result.heightBelowMinimum)
    }

    function test_invalidValuesUseBoundedFallbacks() {
        const result = IslandSizing.resolve({
            source: "unknown",
            minimumWidth: -1,
            preferredWidth: "invalid",
            maximumWidth: 0,
            minimumHeight: NaN,
            preferredHeight: undefined,
            maximumHeight: -20
        }, {}, {
            width: 330,
            height: 88
        })

        compare(result.source, "declared")
        compare(result.requestedWidth, 330)
        compare(result.requestedHeight, 88)
        compare(result.resolvedWidth, 330)
        compare(result.resolvedHeight, 88)
    }

    function test_maximumCannotFallBelowMinimum() {
        const result = IslandSizing.resolve({
            minimumWidth: 300,
            preferredWidth: 500,
            maximumWidth: 200,
            minimumHeight: 80,
            preferredHeight: 120,
            maximumHeight: 40
        }, {
            availableWidth: 1000,
            availableHeight: 1000
        })

        compare(result.minimumWidth, 300)
        compare(result.maximumWidth, 300)
        compare(result.requestedWidth, 300)
        compare(result.minimumHeight, 80)
        compare(result.maximumHeight, 80)
        compare(result.requestedHeight, 80)
    }
}
