import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperEditorSelection.js" as Selection

TestCase {
    name: "WallpaperEditorSelection"

    function document(id) {
        return {
            project: {
                id: id || "project-a",
                assets: [
                    {
                        id: "asset-a"
                    },
                    {
                        id: "asset-b"
                    }
                ],
                markers: [
                    {
                        id: "marker-a"
                    },
                    {
                        id: "marker-b"
                    }
                ],
                tracks: [
                    {
                        id: "track-a",
                        clips: [
                            {
                                id: "clip-a",
                                startMs: 0
                            },
                            {
                                id: "clip-b",
                                startMs: 1000
                            }
                        ]
                    },
                    {
                        id: "track-b",
                        clips: [
                            {
                                id: "clip-c",
                                startMs: 0
                            }
                        ]
                    }
                ]
            }
        };
    }

    function test_emptySelectionIsTaggedAndProjectScoped() {
        const result = Selection.empty("project-a");
        compare(result.kind, "none");
        compare(result.projectId, "project-a");
        compare(result.clipIds.length, 0);
    }

    function test_assetAndMarkerSelectionsAreExclusive() {
        let state = Selection.selectAsset(document(), "asset-a");
        compare(state.kind, "asset");
        compare(state.assetId, "asset-a");
        state = Selection.selectMarker(state, document(), "marker-a", true);
        compare(state.kind, "marker");
        compare(state.markerId, "marker-a");
        compare(state.assetId, "");
    }

    function test_markerToggleClearsOnlyCurrentMarker() {
        let state = Selection.selectMarker(null, document(), "marker-a", true);
        state = Selection.selectMarker(state, document(), "marker-a", true);
        compare(state.kind, "none");
        state = Selection.selectMarker(state, document(), "marker-b", true);
        compare(state.markerId, "marker-b");
    }

    function test_clipSelectionPreservesTimelineModes() {
        let state = Selection.selectClip(null, document(), "track-a", "clip-a", "replace");
        state = Selection.selectClip(state, document(), "track-a", "clip-b", "add");
        compare(state.kind, "clips");
        compare(state.clipIds.length, 2);
        compare(state.primaryClipId, "clip-b");
        compare(Selection.timelineState(state).anchorClipId, "clip-b");
    }

    function test_trackSelectionReplacesOtherKinds() {
        const asset = Selection.selectAsset(document(), "asset-a");
        const track = Selection.selectTrack(asset, document(), "track-b");
        compare(track.kind, "track");
        compare(track.trackId, "track-b");
        compare(track.assetId, "");
    }

    function test_selectAllClipsUsesStableCanonicalOrder() {
        const state = Selection.selectAllClips(document());
        compare(state.kind, "clips");
        compare(state.clipIds, ["clip-a", "clip-b", "clip-c"]);
    }

    function test_normalizeDropsDeletedAndCrossProjectSelection() {
        const asset = Selection.selectAsset(document(), "asset-a");
        const withoutAsset = document();
        withoutAsset.project.assets = [];
        compare(Selection.normalize(asset, withoutAsset).kind, "none");
        compare(Selection.normalize(asset, document("project-b")).kind, "none");
    }

    function test_markerRemovalOnlyClearsRemovedIdentity() {
        const selectedA = Selection.selectMarker(null, document(), "marker-a", false);
        const selectedB = Selection.selectMarker(null, document(), "marker-b", false);
        const remaining = document();
        remaining.project.markers = [
            {
                id: "marker-b"
            }
        ];
        compare(Selection.normalize(selectedA, remaining).kind, "none");
        compare(Selection.normalize(selectedB, remaining).markerId, "marker-b");
    }

    function test_invalidIdentityNeverCreatesPartialSelection() {
        compare(Selection.selectAsset(document(), "missing").kind, "none");
        compare(Selection.selectMarker(null, document(), "missing", true).kind, "none");
        compare(Selection.selectTrack(null, document(), "missing").kind, "none");
    }
}
