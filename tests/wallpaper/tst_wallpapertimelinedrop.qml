import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelineDrop.js" as Drop

TestCase {
    name: "WallpaperTimelineDrop"

    function document(kind, tracks) {
        return {
            schemaVersion: 1,
            project: {
                id: "project",
                name: "Project",
                durationMs: 0,
                assets: [
                    {
                        id: "asset",
                        name: "Asset",
                        kind: kind
                    }
                ],
                tracks: tracks || [],
                markers: [],
                userProperties: [],
                outputTargets: []
            }
        };
    }

    function request(extra) {
        return Object.assign({
            assetId: "asset",
            clipId: "clip",
            newTrackId: "track",
            startMs: 0,
            sourceDurationMs: 4000
        }, extra || ({}));
    }

    function test_firstDropCreatesTypedTrackAndDuration() {
        const result = Drop.plan(document("video"), request());
        verify(result.accepted);
        compare(result.trackId, "track");
        compare(result.document.project.tracks[0].type, "media");
        compare(result.document.project.tracks[0].clips[0].durationMs, 4000);
        compare(result.document.project.durationMs, 4000);
    }

    function test_audioCreatesAudioTrack() {
        const result = Drop.plan(document("audio"), request());
        verify(result.accepted);
        compare(result.document.project.tracks[0].type, "audio");
    }

    function test_reusesCompatibleTrack() {
        const tracks = [
            {
                id: "existing",
                name: "Visual",
                type: "media",
                enabled: true,
                locked: false,
                clips: []
            }
        ];
        const result = Drop.plan(document("static", tracks), request({
            newTrackId: "unused",
            startMs: 2000
        }));
        verify(result.accepted);
        compare(result.trackId, "existing");
        compare(result.document.project.tracks.length, 1);
        compare(result.document.project.durationMs, 7000);
    }

    function test_explicitIncompatibleTrackFailsAtomically() {
        const source = document("video", [
            {
                id: "audio",
                name: "Audio",
                type: "audio",
                enabled: true,
                locked: false,
                clips: []
            }
        ]);
        const result = Drop.plan(source, request({
            trackId: "audio"
        }));
        verify(!result.accepted);
        compare(source.project.durationMs, 0);
        compare(source.project.tracks[0].clips.length, 0);
    }

    function test_missingStableIdentityFails() {
        verify(!Drop.plan(document("video"), request({
            clipId: ""
        })).accepted);
        verify(!Drop.plan(document("video"), request({
            newTrackId: ""
        })).accepted);
    }
}
