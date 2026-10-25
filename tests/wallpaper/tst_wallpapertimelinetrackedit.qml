import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelineTrackEdit.js" as Tracks

TestCase {
    name: "WallpaperTimelineTrackEdit"

    function project() {
        return {
            schemaVersion: 1,
            project: {
                id: "editor",
                tracks: [
                    {
                        id: "visual",
                        name: "Visual",
                        type: "media",
                        enabled: true,
                        locked: false,
                        clips: []
                    },
                    {
                        id: "audio",
                        name: "Audio",
                        type: "audio",
                        enabled: true,
                        locked: false,
                        clips: []
                    }
                ]
            }
        };
    }

    function test_addsTypedTrackAtBoundedPositionImmutably() {
        const original = project();
        const result = Tracks.addTrack(original, "triggers", " Triggers ", "trigger", 1);
        verify(result.accepted);
        compare(result.document.project.tracks[1].id, "triggers");
        compare(result.document.project.tracks[1].name, "Triggers");
        compare(result.document.project.tracks[1].type, "trigger");
        compare(result.document.project.tracks[1].clips.length, 0);
        compare(original.project.tracks.length, 2);
    }

    function test_rejectsDuplicateMissingAndUnsupportedIdentity() {
        verify(!Tracks.addTrack(project(), "visual", "Other", "media", 0).accepted);
        verify(!Tracks.addTrack(project(), "", "Other", "media", 0).accepted);
        verify(!Tracks.addTrack(project(), "other", "", "media", 0).accepted);
        verify(!Tracks.addTrack(project(), "other", "Other", "shader", 0).accepted);
    }

    function test_supportsEveryDeclaredTrackType() {
        for (const type of Tracks.trackTypes) {
            const result = Tracks.addTrack(project(), "new-" + type, "New " + type, type, 100);
            verify(result.accepted);
            compare(result.document.project.tracks[2].type, type);
        }
    }

    function test_updatesOnlyRequestedTrackWithoutAliasing() {
        const original = project();
        const result = Tracks.updateTrack(original, "visual", {
            name: "Foreground",
            enabled: false,
            locked: true
        });
        verify(result.accepted);
        compare(result.document.project.tracks[0].name, "Foreground");
        verify(!result.document.project.tracks[0].enabled);
        verify(result.document.project.tracks[0].locked);
        compare(original.project.tracks[0].name, "Visual");
        verify(original.project.tracks[0].enabled);
    }

    function test_reordersAndClampsWithoutChangingTrackIdentity() {
        const original = project();
        let result = Tracks.reorderTrack(original, "visual", 99);
        verify(result.accepted);
        compare(result.document.project.tracks[1].id, "visual");
        compare(result.document.project.tracks[1], original.project.tracks[0]);
        compare(original.project.tracks[0].id, "visual");
        result = Tracks.reorderTrack(result.document, "visual", -20);
        compare(result.document.project.tracks[0].id, "visual");
    }

    function test_noOpReorderReturnsSameDocument() {
        const original = project();
        const result = Tracks.reorderTrack(original, "visual", 0);
        verify(result.accepted);
        compare(result.document, original);
    }

    function test_removesOnlyEmptyTrack() {
        const original = project();
        const removed = Tracks.removeTrack(original, "audio");
        verify(removed.accepted);
        compare(removed.document.project.tracks.length, 1);
        compare(removed.document.project.tracks[0].id, "visual");
        compare(original.project.tracks.length, 2);
        original.project.tracks[0].clips.push({
            id: "clip"
        });
        verify(!Tracks.removeTrack(original, "visual").accepted);
    }

    function test_rejectsMissingTrackAndInvalidReorder() {
        verify(!Tracks.removeTrack(project(), "missing").accepted);
        verify(!Tracks.updateTrack(project(), "missing", {
            locked: true
        }).accepted);
        verify(!Tracks.reorderTrack(project(), "visual", "nope").accepted);
    }

    function test_confirmedRemovalKeepsAssetsAndOtherTracks() {
        const original = project();
        original.project.assets = [{ id: "asset", sourcePath: "/untouched.png" }];
        original.project.durationMs = 10000;
        original.project.tracks[0].clips = [{ id: "one" }, { id: "two" }];
        const before = JSON.stringify(original);
        const review = Tracks.removalReview(original, "visual");
        compare(review.clipCount, 2);
        compare(review.name, "Visual");
        const result = Tracks.removeTrack(original, "visual", review);
        verify(result.accepted);
        compare(result.document.project.tracks.length, 1);
        compare(result.document.project.tracks[0], original.project.tracks[1]);
        compare(result.document.project.assets, original.project.assets);
        compare(result.document.project.durationMs, 10000);
        compare(JSON.stringify(original), before);
    }

    function test_rejectsStaleAndCrossProjectConfirmation() {
        const original = project();
        original.project.tracks[0].clips = [{ id: "one", durationMs: 1000 }];
        const review = Tracks.removalReview(original, "visual");
        original.project.tracks[0].clips[0].durationMs = 2000;
        verify(!Tracks.removeTrack(original, "visual", review).accepted);
        original.project.tracks[0].clips[0].durationMs = 1000;
        original.project.id = "another-project";
        verify(!Tracks.removeTrack(original, "visual", review).accepted);
        original.project.id = "editor";
        verify(!Tracks.removeTrack(original, "audio", review).accepted);
        verify(!Tracks.removeTrack(original, "visual", true).accepted);
        verify(Tracks.removeTrack(original, "visual", review).accepted);
    }

    function test_emptyTrackBecomingPopulatedRequiresNewReview() {
        const original = project();
        const review = Tracks.removalReview(original, "visual");
        original.project.tracks[0].clips = [{ id: "new" }];
        verify(!Tracks.removeTrack(original, "visual", review).accepted);
        verify(!Tracks.removeTrack(original, "visual").accepted);
        compare(original.project.tracks.length, 2);
    }

    function test_missingReviewHasNoMutation() {
        compare(Tracks.removalReview(null, "visual"), null);
        compare(Tracks.removalReview(project(), "missing"), null);
        verify(!Tracks.removeTrack(null, "visual").accepted);
    }

    function test_enforcesCanonicalTrackLimit() {
        const document = project();
        document.project.tracks = [];
        for (let index = 0; index < 64; ++index)
            document.project.tracks.push({
                id: "track-" + index,
                clips: []
            });
        verify(!Tracks.addTrack(document, "overflow", "Overflow", "media", 64).accepted);
    }
}
