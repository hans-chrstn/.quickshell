import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelineBatchEdit.js" as Batch

TestCase {
    name: "WallpaperTimelineBatchEdit"

    function project() {
        return {
            schemaVersion: 1,
            project: {
                id: "editor",
                durationMs: 12000,
                assets: [
                    {
                        id: "asset",
                        kind: "video"
                    }
                ],
                tracks: [
                    {
                        id: "front",
                        type: "media",
                        enabled: true,
                        locked: false,
                        clips: [
                            {
                                id: "one",
                                assetId: "asset",
                                startMs: 1000,
                                durationMs: 2000,
                                sourceInMs: 0,
                                loop: false
                            },
                            {
                                id: "two",
                                assetId: "asset",
                                startMs: 5000,
                                durationMs: 2000,
                                sourceInMs: 0,
                                loop: false
                            }
                        ]
                    },
                    {
                        id: "back",
                        type: "media",
                        enabled: true,
                        locked: false,
                        clips: [
                            {
                                id: "three",
                                assetId: "asset",
                                startMs: 2000,
                                durationMs: 2000,
                                sourceInMs: 0,
                                loop: false
                            }
                        ]
                    }
                ]
            }
        };
    }

    function test_removesSelectionAtomicallyAndImmutably() {
        const original = project();
        const result = Batch.apply(original, {
            type: "remove-clips",
            clipIds: ["one", "three"]
        });
        verify(result.accepted);
        compare(result.document.project.tracks[0].clips.length, 1);
        compare(result.document.project.tracks[1].clips.length, 0);
        compare(original.project.tracks[0].clips.length, 2);
        compare(JSON.stringify(result.changedClipIds), JSON.stringify(["one", "three"]));
    }

    function test_rejectsWholeSelectionWhenOneClipIsMissingOrLocked() {
        const original = project();
        verify(!Batch.apply(original, {
            type: "remove-clips",
            clipIds: ["one", "missing"]
        }).accepted);
        original.project.tracks[1].locked = true;
        verify(!Batch.apply(original, {
            type: "remove-clips",
            clipIds: ["one", "three"]
        }).accepted);
        compare(original.project.tracks[0].clips.length, 2);
        compare(original.project.tracks[1].clips.length, 1);
    }

    function test_nudgesMultipleClipsAsOneOperation() {
        const original = project();
        const result = Batch.apply(original, {
            type: "nudge-clips",
            clipIds: ["one", "two"],
            deltaMs: 500
        });
        verify(result.accepted);
        compare(result.document.project.tracks[0].clips[0].startMs, 1500);
        compare(result.document.project.tracks[0].clips[1].startMs, 5500);
        compare(original.project.tracks[0].clips[0].startMs, 1000);
    }

    function test_adjacentSelectionMovesAgainstFinalBatchLayout() {
        const original = project();
        original.project.tracks[0].clips[1].startMs = 3000;
        const result = Batch.apply(original, {
            type: "nudge-clips",
            clipIds: ["one", "two"],
            deltaMs: 1000
        });
        verify(result.accepted);
        compare(result.document.project.tracks[0].clips[0].startMs, 2000);
        compare(result.document.project.tracks[0].clips[1].startMs, 4000);
    }

    function test_nudgeRejectsBoundaryAndCollisionWithoutPartialResult() {
        let original = project();
        verify(!Batch.apply(original, {
            type: "nudge-clips",
            clipIds: ["one"],
            deltaMs: -2000
        }).accepted);
        original.project.tracks[0].clips[1].startMs = 3500;
        verify(!Batch.apply(original, {
            type: "nudge-clips",
            clipIds: ["one"],
            deltaMs: 1000
        }).accepted);
        compare(original.project.tracks[0].clips[0].startMs, 1000);
    }

    function test_duplicatesAllOrNothingWithCallerOwnedIds() {
        const original = project();
        const result = Batch.apply(original, {
            type: "duplicate-clips",
            clipIds: ["one", "three"],
            newClipIds: {
                one: "one-copy",
                three: "three-copy"
            },
            startMsByClipId: {
                one: 8000,
                three: 9000
            },
            sourceDurationMsByClipId: {
                one: 4000,
                three: 4000
            }
        });
        verify(result.accepted);
        compare(JSON.stringify(result.changedClipIds), JSON.stringify(["one-copy", "three-copy"]));
        compare(result.document.project.tracks[0].clips.length, 3);
        compare(result.document.project.tracks[1].clips.length, 2);
        const rejected = Batch.apply(original, {
            type: "duplicate-clips",
            clipIds: ["one", "three"],
            newClipIds: {
                one: "copy"
            },
            startMsByClipId: {
                one: 8000,
                three: 9000
            }
        });
        verify(!rejected.accepted);
        compare(rejected.document, null);
        compare(original.project.tracks[0].clips.length, 2);
    }

    function test_splitsMultipleClipsOnlyWhenEverySplitIsValid() {
        const original = project();
        const result = Batch.apply(original, {
            type: "split-clips",
            clipIds: ["one", "three"],
            timeMs: 2500,
            newClipIds: {
                one: "one-right",
                three: "three-right"
            },
            sourceDurationMsByClipId: {
                one: 5000,
                three: 5000
            }
        });
        verify(result.accepted);
        compare(result.document.project.tracks[0].clips.length, 3);
        compare(result.document.project.tracks[1].clips.length, 2);
        const rejected = Batch.apply(original, {
            type: "split-clips",
            clipIds: ["one", "two"],
            timeMs: 2500,
            newClipIds: {
                one: "one-right",
                two: "two-right"
            }
        });
        verify(!rejected.accepted);
        compare(rejected.document, null);
        compare(original.project.tracks[0].clips.length, 2);
    }

    function test_rejectsEmptyAndUnsupportedCommands() {
        verify(!Batch.apply(project(), {
            type: "remove-clips",
            clipIds: []
        }).accepted);
        verify(!Batch.apply(project(), {
            type: "paint-clips",
            clipIds: ["one"]
        }).accepted);
        verify(!Batch.apply(project(), null).accepted);
    }
}
