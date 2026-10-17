import QtQuick
import QtTest
import "../../components/layout/BoundedSplitModel.js" as Split

TestCase {
    name: "BoundedSplitModel"

    function test_distributesOnlySpaceBeyondMinimums() {
        const result = Split.resolve(1000, 10, [150, 300, 200], [1, 2, 1]);
        compare(result.totalLength, 1000);
        fuzzyCompare(result.sizes[0], 232.5, 0.001);
        fuzzyCompare(result.sizes[1], 465, 0.001);
        fuzzyCompare(result.sizes[2], 282.5, 0.001);
        verify(!result.overflow);
    }

    function test_overflowUsesExactMinimumContent() {
        const result = Split.resolve(500, 10, [150, 300, 200], [1, 1, 1]);
        verify(result.overflow);
        compare(result.minimumTotalLength, 670);
        compare(result.totalLength, 670);
        compare(JSON.stringify(result.sizes), JSON.stringify([150, 300, 200]));
    }

    function test_dragTransfersOnlyBetweenAdjacentPanes() {
        const initial = Split.resolve(1000, 10, [150, 300, 200], [1, 2, 1]);
        const result = Split.drag(initial, 0, 50);
        verify(result.accepted);
        fuzzyCompare(result.layout.sizes[0], initial.sizes[0] + 50, 0.001);
        fuzzyCompare(result.layout.sizes[1], initial.sizes[1] - 50, 0.001);
        fuzzyCompare(result.layout.sizes[2], initial.sizes[2], 0.001);
        fuzzyCompare(result.layout.totalLength, initial.totalLength, 0.001);
    }

    function test_dragClampsBothPaneMinimums() {
        const initial = Split.resolve(1000, 10, [150, 300, 200], [1, 2, 1]);
        let result = Split.drag(initial, 0, -9999);
        compare(result.layout.sizes[0], 150);
        result = Split.drag(initial, 0, 9999);
        compare(result.layout.sizes[1], 300);
    }

    function test_draggedWeightsRestoreSameSizes() {
        const initial = Split.resolve(1000, 10, [150, 300, 200], [1, 2, 1]);
        const dragged = Split.drag(initial, 1, -80).layout;
        const restored = Split.resolve(1000, 10, [150, 300, 200], dragged.extraWeights);
        for (let index = 0; index < dragged.sizes.length; ++index)
            fuzzyCompare(restored.sizes[index], dragged.sizes[index], 0.001);
    }

    function test_weightsAdaptResponsivelyAtNewLength() {
        const initial = Split.resolve(1000, 10, [150, 300, 200], [1, 2, 1]);
        const dragged = Split.drag(initial, 0, 40).layout;
        const smaller = Split.resolve(800, 10, [150, 300, 200], dragged.extraWeights);
        verify(!smaller.overflow);
        compare(smaller.totalLength, 800);
        verify(smaller.sizes[0] >= 150);
        verify(smaller.sizes[1] >= 300);
        verify(smaller.sizes[2] >= 200);
    }

    function test_invalidDividerFailsWithoutChangingLayout() {
        const initial = Split.resolve(1000, 10, [150, 300, 200], [1, 1, 1]);
        const result = Split.drag(initial, 4, 100);
        verify(!result.accepted);
        compare(result.layout, initial);
    }

    function test_malformedWeightsRemainFinite() {
        const result = Split.resolve(700, -10, [100, 200], [0, Number.NaN]);
        compare(result.gap, 0);
        verify(Number.isFinite(result.sizes[0]));
        verify(Number.isFinite(result.sizes[1]));
        fuzzyCompare(result.sizes[0] + result.sizes[1], 700, 0.001);
    }
}
