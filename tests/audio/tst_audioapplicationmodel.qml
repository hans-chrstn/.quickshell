import QtQuick
import QtTest
import "../../services/audio/AudioApplicationModel.js" as AudioApplicationModel

TestCase {
    name: "AudioApplicationModel"

    function stream(id, role, applicationKey, overrides) {
        return Object.assign({
            id: id,
            sessionId: "pipewire-serial:" + id,
            stableKey: "pipewire-serial:" + id,
            role: role,
            applicationKey: applicationKey,
            applicationIdentityKind: applicationKey.length > 0 ? "application-id" : "none",
            applicationName: "",
            applicationBinary: "",
            displayName: "Stream " + id,
            iconName: "",
            ready: true,
            volume: 0.5,
            muted: false,
            capabilities: {
                volumeRead: true,
                volumeWrite: true,
                muteRead: true,
                muteWrite: true,
                routeRead: true,
                routeWrite: false
            }
        }, overrides || ({}));
    }

    function test_groupsDuplicatePlaybackStreamsByStableApplicationIdentity() {
        const groups = AudioApplicationModel.groupedApplications([stream(11, "playback-stream", "application-id:browser", {
                applicationName: "Browser",
                volume: 0.4
            }), stream(12, "playback-stream", "application-id:browser", {
                applicationName: "Browser",
                volume: 0.6
            })]);

        compare(groups.playingCount, 1);
        compare(groups.recordingCount, 0);
        compare(groups.streamCount, 2);
        compare(groups.playing[0].streamCount, 2);
        compare(groups.playing[0].volume, 0.5);
        verify(groups.playing[0].mixedVolume);
        compare(groups.playing[0].streamSessionIds.join(","), "pipewire-serial:11,pipewire-serial:12");
    }

    function test_separatesPlayingAndRecordingForSameApplication() {
        const groups = AudioApplicationModel.groupedApplications([stream(20, "playback-stream", "application-id:meeting", {
                applicationName: "Meeting"
            }), stream(21, "recording-stream", "application-id:meeting", {
                applicationName: "Meeting"
            })]);

        compare(groups.playingCount, 1);
        compare(groups.recordingCount, 1);
        compare(groups.playing[0].direction, "output");
        compare(groups.recording[0].direction, "input");
        verify(groups.playing[0].key !== groups.recording[0].key);
    }

    function test_similarNamesDoNotMergeDistinctStableIdentities() {
        const groups = AudioApplicationModel.groupedApplications([stream(30, "playback-stream", "application-id:org.alpha", {
                applicationName: "Player"
            }), stream(31, "playback-stream", "application-id:org.beta", {
                applicationName: "Player"
            })]);

        compare(groups.playingCount, 2);
        verify(groups.playing[0].key !== groups.playing[1].key);
    }

    function test_unidentifiedStreamsRemainSeparateAndNonAudioIsIgnored() {
        const groups = AudioApplicationModel.groupedApplications([stream(40, "playback-stream", "", {
                displayName: "Unknown"
            }), stream(41, "playback-stream", "", {
                displayName: "Unknown"
            }), stream(42, "output-device", "application-id:not-an-app")]);

        compare(groups.playingCount, 2);
        compare(groups.streamCount, 2);
        compare(groups.playing[0].applicationKey, "");
        compare(groups.playing[1].applicationKey, "");
    }

    function test_groupCapabilitiesFailClosedAndMuteStateIsTruthful() {
        const groups = AudioApplicationModel.groupedApplications([stream(50, "recording-stream", "binary:recorder", {
                muted: true
            }), stream(51, "recording-stream", "binary:recorder", {
                muted: false,
                capabilities: {
                    volumeRead: true,
                    volumeWrite: false,
                    muteRead: true,
                    muteWrite: false,
                    routeRead: true,
                    routeWrite: false
                }
            })]);
        const group = groups.recording[0];

        verify(!group.muted);
        verify(group.mixedMute);
        verify(group.capabilities.volumeRead);
        verify(!group.capabilities.volumeWrite);
        verify(!group.capabilities.muteWrite);
        verify(!group.capabilities.routeWrite);
    }

    function test_displayMetadataIsDeterministicBoundedAndDefensive() {
        const source = stream(60, "playback-stream", "application-id:music", {
            applicationName: "Zeta",
            applicationBinary: "music-bin",
            iconName: "zeta-icon",
            displayName: "A".repeat(300)
        });
        const second = stream(61, "playback-stream", "application-id:music", {
            applicationName: "Alpha",
            iconName: "alpha-icon"
        });
        const groups = AudioApplicationModel.groupedApplications([source, second]);
        const group = groups.playing[0];

        compare(group.displayName, "Alpha");
        compare(group.iconName, "alpha-icon");
        verify(group.streams[0] !== source);
        group.streams[0].capabilities.volumeWrite = false;
        verify(source.capabilities.volumeWrite);
    }

    function test_derivesRouteSummaryFromObservedLinks() {
        const records = [stream(70, "playback-stream", "application-id:player", {
                applicationName: "Player"
            }),
            {
                id: 90,
                role: "output-device",
                displayName: "Studio Output"
            }
        ];
        const groups = AudioApplicationModel.groupedApplications(records, [
            {
                sourceId: 70,
                targetId: 90
            }
        ]);

        compare(groups.playing[0].routeCount, 1);
        compare(groups.playing[0].routeSummary, "Studio Output");
        compare(groups.playing[0].routeNames.join(","), "Studio Output");
    }

    function test_routeSummaryFailsClosedWithoutAnObservedLink() {
        const groups = AudioApplicationModel.groupedApplications([stream(80, "recording-stream", "binary:recorder")], []);

        compare(groups.recording[0].routeCount, 0);
        compare(groups.recording[0].routeSummary, "Route unavailable");
    }

    function test_listRowsOmitsEmptySectionsAndRedundantSingleSectionHeading() {
        const groups = AudioApplicationModel.groupedApplications([stream(90, "playback-stream", "binary:music", {
                applicationName: "Music"
            })]);
        const rows = AudioApplicationModel.listRows(groups);

        compare(rows.length, 1);
        compare(rows[0].kind, "application");
        compare(rows[0].displayName, "Music");
    }

    function test_listRowsAddsHeadingsOnlyWhenBothDirectionsAreActive() {
        const groups = AudioApplicationModel.groupedApplications([stream(100, "playback-stream", "binary:meeting", {
                applicationName: "Meeting"
            }), stream(101, "recording-stream", "binary:meeting", {
                applicationName: "Meeting"
            })]);
        const rows = AudioApplicationModel.listRows(groups);

        compare(rows.length, 4);
        compare(rows[0].key, "section:playing");
        compare(rows[1].section, "playing");
        compare(rows[2].key, "section:recording");
        compare(rows[3].section, "recording");
    }

    function test_listRowsIsEmptyWhenNoApplicationsAreActive() {
        compare(AudioApplicationModel.listRows(AudioApplicationModel.groupedApplications([])).length, 0);
    }

    function test_applicationLookupCoversPlaybackAndRecording() {
        const groups = AudioApplicationModel.groupedApplications([stream(110, "playback-stream", "binary:player"), stream(111, "recording-stream", "binary:recorder")]);

        compare(AudioApplicationModel.applicationByKey(groups, groups.playing[0].key).section, "playing");
        compare(AudioApplicationModel.applicationByKey(groups, groups.recording[0].key).section, "recording");
        compare(AudioApplicationModel.applicationByKey(groups, "missing"), null);
    }

    function test_applicationSelectionSkipsHeadingsAndRetainsStableIdentity() {
        const groups = AudioApplicationModel.groupedApplications([stream(120, "playback-stream", "binary:alpha", {
                applicationName: "Alpha"
            }), stream(121, "playback-stream", "binary:beta", {
                applicationName: "Beta"
            }), stream(122, "recording-stream", "binary:recorder", {
                applicationName: "Recorder"
            })]);
        const rows = AudioApplicationModel.listRows(groups);
        const alphaKey = groups.playing[0].key;
        const betaKey = groups.playing[1].key;
        const recorderKey = groups.recording[0].key;

        compare(AudioApplicationModel.applicationSelectionKey(rows, "", "retain"), alphaKey);
        compare(AudioApplicationModel.applicationSelectionKey(rows, alphaKey, "next"), betaKey);
        compare(AudioApplicationModel.applicationSelectionKey(rows, betaKey, "next"), recorderKey);
        compare(AudioApplicationModel.applicationSelectionKey(rows, recorderKey, "next"), recorderKey);
        compare(AudioApplicationModel.applicationSelectionKey(rows, recorderKey, "previous"), betaKey);
        compare(AudioApplicationModel.applicationSelectionKey(rows, betaKey, "retain"), betaKey);
        compare(AudioApplicationModel.applicationSelectionKey(rows, "missing", "previous"), recorderKey);
        compare(AudioApplicationModel.applicationSelectionKey(rows, betaKey, "first"), alphaKey);
        compare(AudioApplicationModel.applicationSelectionKey(rows, betaKey, "last"), recorderKey);
        compare(AudioApplicationModel.applicationSelectionKey([], betaKey, "retain"), "");
    }
}
