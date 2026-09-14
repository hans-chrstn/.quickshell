import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelineEdit.js" as Edit

TestCase {
    name: "WallpaperTimelineEdit"

    function project() {
        return {
            schemaVersion: 1,
            project: {
                id: "editor",
                durationMs: 20000,
                assets: [
                    {
                        id: "sky",
                        kind: "video"
                    },
                    {
                        id: "still",
                        kind: "static"
                    }
                ],
                tracks: [
                    {
                        id: "front",
                        type: "media",
                        clips: []
                    },
                    {
                        id: "back",
                        type: "media",
                        clips: [],
                        locked: false
                    },
                    {
                        id: "triggers",
                        type: "trigger",
                        clips: []
                    }
                ]
            }
        };
    }

    function test_insertsSortedClipWithoutMutatingInput() {
        const original = project();
        const later = Edit.insertClip(original, "front", "sky", 9000, 4000, "later");
        verify(later.accepted);
        const earlier = Edit.insertClip(later.document, "front", "still", 1000, 0, "earlier");
        verify(earlier.accepted);
        compare(earlier.document.project.tracks[0].clips[0].id, "earlier");
        compare(earlier.document.project.tracks[0].clips[1].id, "later");
        compare(original.project.tracks[0].clips.length, 0);
    }

    function test_rejectsDuplicateAndIncompatibleDrop() {
        const inserted = Edit.insertClip(project(), "front", "sky", 0, 4000, "clip-1").document;
        verify(!Edit.insertClip(inserted, "front", "still", 5000, 0, "clip-1").accepted);
        verify(!Edit.insertClip(inserted, "triggers", "sky", 0, 4000, "wrong").accepted);
    }

    function test_movesAcrossTracksAndClampsProjectTime() {
        const original = Edit.insertClip(project(), "front", "sky", 1000, 4000, "clip-1").document;
        const moved = Edit.moveClip(original, "clip-1", "back", 19000);
        verify(moved.accepted);
        compare(moved.document.project.tracks[0].clips.length, 0);
        compare(moved.document.project.tracks[1].clips[0].startMs, 19000);
        compare(moved.document.project.tracks[1].clips[0].durationMs, 1000);
        compare(original.project.tracks[0].clips.length, 1);
    }

    function test_resizesFiniteAndLoopedClip() {
        const inserted = Edit.insertClip(project(), "front", "sky", 2000, 5000, "clip-1").document;
        const finite = Edit.resizeClipEnd(inserted, "clip-1", 18000, 5000, false);
        verify(finite.accepted);
        compare(finite.document.project.tracks[0].clips[0].durationMs, 5000);
        const looped = Edit.resizeClipEnd(inserted, "clip-1", 18000, 5000, true);
        verify(looped.accepted);
        compare(looped.document.project.tracks[0].clips[0].durationMs, 16000);
        verify(looped.document.project.tracks[0].clips[0].loop);
    }

    function test_trimsStartAndPreservesInput() {
        const inserted = Edit.insertClip(project(), "front", "sky", 1000, 6000, "clip-1").document;
        const trimmed = Edit.trimClipStart(inserted, "clip-1", 3000, 6000);
        verify(trimmed.accepted);
        const clip = trimmed.document.project.tracks[0].clips[0];
        compare(clip.startMs, 3000);
        compare(clip.durationMs, 4000);
        compare(clip.sourceInMs, 2000);
        compare(inserted.project.tracks[0].clips[0].startMs, 1000);
    }

    function test_removesOnlyRequestedClip() {
        let document = Edit.insertClip(project(), "front", "sky", 0, 4000, "one").document;
        document = Edit.insertClip(document, "front", "still", 5000, 0, "two").document;
        const removed = Edit.removeClip(document, "one");
        verify(removed.accepted);
        compare(removed.document.project.tracks[0].clips.length, 1);
        compare(removed.document.project.tracks[0].clips[0].id, "two");
        compare(document.project.tracks[0].clips.length, 2);
    }

    function test_rejectsMissingAndLockedTargets() {
        const document = project();
        document.project.tracks[1].locked = true;
        verify(!Edit.insertClip(document, "missing", "sky", 0, 4000, "clip").accepted);
        const inserted = Edit.insertClip(document, "front", "sky", 0, 4000, "clip").document;
        verify(!Edit.moveClip(inserted, "clip", "back", 1000).accepted);
        verify(!Edit.removeClip(inserted, "absent").accepted);

        const lockedSource = project();
        const withClip = Edit.insertClip(lockedSource, "front", "sky", 0, 4000, "source-locked").document;
        withClip.project.tracks[0].locked = true;
        verify(!Edit.moveClip(withClip, "source-locked", "back", 1000).accepted);
    }

    function test_rejectsOverlapOnExclusiveTrack() {
        const first = Edit.insertClip(project(), "front", "sky", 0, 4000, "one").document;
        verify(!Edit.insertClip(first, "front", "still", 3000, 0, "two").accepted);
        const second = Edit.insertClip(first, "front", "still", 5000, 0, "two").document;
        verify(!Edit.moveClip(second, "two", "front", 3000).accepted);
        verify(!Edit.resizeClipEnd(second, "one", 6000, 8000, false).accepted);
    }

    function test_duplicatesWithoutAliasingOriginal() {
        const inserted = Edit.insertClip(project(), "front", "sky", 0, 4000, "one").document;
        const duplicated = Edit.duplicateClip(inserted, "one", "two", 5000, 4000);
        verify(duplicated.accepted);
        compare(duplicated.document.project.tracks[0].clips.length, 2);
        compare(duplicated.document.project.tracks[0].clips[1].id, "two");
        compare(inserted.project.tracks[0].clips.length, 1);
        verify(!Edit.duplicateClip(inserted, "one", "one", 5000, 4000).accepted);
    }

    function test_splitsFiniteClipAtExactSourcePhase() {
        const inserted = Edit.insertClip(project(), "front", "sky", 1000, 6000, "whole").document;
        const split = Edit.splitClip(inserted, "whole", 3500, "right", 6000);
        verify(split.accepted);
        const clips = split.document.project.tracks[0].clips;
        compare(clips.length, 2);
        compare(clips[0].durationMs, 2500);
        compare(clips[1].startMs, 3500);
        compare(clips[1].durationMs, 3500);
        compare(clips[1].sourceInMs, 2500);
        compare(inserted.project.tracks[0].clips.length, 1);
    }

    function test_rejectsBoundaryAndLoopedSplit() {
        const inserted = Edit.insertClip(project(), "front", "sky", 1000, 6000, "whole").document;
        verify(!Edit.splitClip(inserted, "whole", 1000, "right", 6000).accepted);
        const looped = Edit.resizeClipEnd(inserted, "whole", 12000, 6000, true).document;
        verify(!Edit.splitClip(looped, "whole", 4000, "right", 6000).accepted);
    }
}
