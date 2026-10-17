import QtQuick
import QtTest
import "../../editor/WallpaperEditorLayout.js" as EditorLayout

TestCase {
    name: "WallpaperEditorLayout"

    function test_preservesAcceptedLargeEditorHierarchy() {
        const layout = EditorLayout.resolve({
            width: 1600,
            height: 992
        });
        verify(!layout.compact);
        verify(!layout.overflowX);
        verify(!layout.overflowY);
        fuzzyCompare(layout.mediaWidth, 280, 1);
        fuzzyCompare(layout.inspectorWidth, 320, 1);
        fuzzyCompare(layout.timelineHeight, 273, 2);
        verify(layout.previewWidth > layout.mediaWidth);
        verify(layout.upperHeight > layout.timelineHeight);
    }

    function test_compactPolicyUsesSmallerBoundedSidePanels() {
        const layout = EditorLayout.resolve({
            width: 900,
            height: 700
        });
        verify(layout.compact);
        verify(!layout.overflowX);
        verify(layout.mediaWidth >= 156);
        verify(layout.previewWidth >= 280);
        verify(layout.inspectorWidth >= 180);
    }

    function test_impossibleViewportReportsRequiredScrollableSize() {
        const layout = EditorLayout.resolve({
            width: 600,
            height: 400
        });
        verify(layout.compact);
        verify(layout.overflowX);
        verify(layout.overflowY);
        verify(layout.requiredWidth > 600);
        verify(layout.requiredHeight > 400);
    }

    function test_horizontalDragOnlyChangesAdjacentRegions() {
        const initial = EditorLayout.resolve({
            width: 1600,
            height: 992
        });
        const changed = EditorLayout.dragHorizontal(initial, 0, 60);
        verify(changed.accepted);
        fuzzyCompare(changed.layout.mediaWidth, initial.mediaWidth + 60, 0.001);
        fuzzyCompare(changed.layout.previewWidth, initial.previewWidth - 60, 0.001);
        fuzzyCompare(changed.layout.inspectorWidth, initial.inspectorWidth, 0.001);
    }

    function test_verticalDragResizesUpperAndTimeline() {
        const initial = EditorLayout.resolve({
            width: 1600,
            height: 992
        });
        const changed = EditorLayout.dragVertical(initial, -80);
        verify(changed.accepted);
        fuzzyCompare(changed.layout.upperHeight, initial.upperHeight - 80, 0.001);
        fuzzyCompare(changed.layout.timelineHeight, initial.timelineHeight + 80, 0.001);
    }

    function test_dragClampsEveryEditorMinimum() {
        const initial = EditorLayout.resolve({
            width: 1600,
            height: 992
        });
        let changed = EditorLayout.dragHorizontal(initial, 0, -9999).layout;
        compare(changed.mediaWidth, 210);
        changed = EditorLayout.dragHorizontal(initial, 1, 9999).layout;
        compare(changed.inspectorWidth, 240);
        changed = EditorLayout.dragVertical(initial, 9999).layout;
        compare(changed.timelineHeight, 170);
    }

    function test_preferencesRestoreAndAdaptAcrossMonitors() {
        const initial = EditorLayout.resolve({
            width: 1600,
            height: 992
        });
        const dragged = EditorLayout.dragHorizontal(initial, 0, 50).layout;
        const verticallyDragged = EditorLayout.dragVertical(dragged, -40).layout;
        const preferences = EditorLayout.preferences(verticallyDragged);
        const restored = EditorLayout.resolve({
            width: 1600,
            height: 992,
            horizontalWeights: preferences.horizontalWeights,
            verticalWeights: preferences.verticalWeights
        });
        fuzzyCompare(restored.mediaWidth, verticallyDragged.mediaWidth, 0.001);
        fuzzyCompare(restored.timelineHeight, verticallyDragged.timelineHeight, 0.001);
        const smaller = EditorLayout.resolve({
            width: 1200,
            height: 760,
            horizontalWeights: preferences.horizontalWeights,
            verticalWeights: preferences.verticalWeights
        });
        verify(!smaller.overflowX);
        verify(!smaller.overflowY);
    }

    function test_policyInputsRemainCallerOwned() {
        const layout = EditorLayout.resolve({
            width: 1000,
            height: 700,
            policy: {
                outerMargin: 20,
                gap: 8,
                headerHeight: 50,
                compactThreshold: 1100,
                compactHorizontalMinimums: [100, 200, 100],
                verticalMinimums: [180, 120]
            }
        });
        verify(layout.compact);
        compare(layout.policy.outerMargin, 20);
        compare(layout.policy.gap, 8);
        compare(layout.innerWidth, 960);
        verify(!layout.overflowX);
    }
}
