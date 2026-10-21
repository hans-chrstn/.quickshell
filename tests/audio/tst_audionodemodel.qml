import QtQuick
import QtTest
import "../../services/audio/AudioNodeModel.js" as AudioNodeModel

TestCase {
    name: "AudioNodeModel"

    function node(id, type, name, properties) {
        return {
            id: id,
            type: type,
            name: name,
            description: "",
            nickname: "",
            properties: properties || ({}),
            ready: true,
            hasAudio: true,
            volume: 0.5,
            muted: false,
            channels: ["FL", "FR"]
        };
    }

    function test_normalizesFourUserFacingRoles() {
        const records = AudioNodeModel.normalizedNodes([node(4, 17, "alsa_output.pci", {
                "media.class": "Audio/Sink",
                "device.api": "alsa"
            }), node(3, 9, "alsa_input.pci", {
                "media.class": "Audio/Source",
                "device.api": "alsa"
            }), node(9, 21, "Firefox", {
                "media.class": "Stream/Output/Audio",
                "application.id": "firefox"
            }), node(7, 13, "Recorder", {
                "media.class": "Stream/Input/Audio",
                "application.id": "recorder"
            })]);

        compare(records.map(record => record.id).join(","), "3,4,7,9");
        compare(records[0].role, "input-device");
        compare(records[1].role, "output-device");
        compare(records[2].role, "recording-stream");
        compare(records[3].role, "playback-stream");
        compare(AudioNodeModel.roleCounts(records).outputDevices, 1);
        compare(AudioNodeModel.roleCounts(records).recordingStreams, 1);
    }

    function test_monitorAndVirtualNodesStaySpecialized() {
        const monitor = AudioNodeModel.normalize(node(11, 9, "alsa_output.pci.monitor", {
            "media.class": "Audio/Source"
        }));
        const effect = AudioNodeModel.normalize(node(12, 17, "easyeffects_sink", {
            "media.class": "Audio/Sink",
            "node.virtual": "true"
        }));

        compare(monitor.role, "specialized-node");
        compare(monitor.specialization, "monitor-source");
        compare(monitor.classificationConfidence, "name-fallback");
        compare(effect.role, "specialized-node");
        compare(effect.specialization, "virtual-output");
        verify(effect.capabilities.preferredDefaultWrite);
    }

    function test_mediaClassRecoversVirtualSourceWithoutAudioTypeFlag() {
        const effectSource = AudioNodeModel.normalize({
            id: 13,
            type: 0,
            name: "easyeffects_source",
            description: "Easy Effects Source",
            properties: {
                "media.class": "Audio/Source/Virtual",
                "node.virtual": "true",
                "object.serial": "120"
            },
            ready: true,
            hasAudio: false
        });

        compare(effectSource.role, "specialized-node");
        compare(effectSource.specialization, "virtual-input");
        compare(effectSource.stableKey, "specialized-node:easyeffects_source");
        verify(!effectSource.capabilities.volumeRead);
    }

    function test_internalAndNonAudioNodesCannotMasqueradeAsDevices() {
        const internalNode = node(20, 17, "Dummy-Driver", {
            "media.class": "Audio/Sink"
        });
        const cameraNode = {
            id: 21,
            type: 10,
            name: "Camera",
            ready: true,
            hasAudio: false,
            properties: {
                "media.class": "Video/Source",
                "device.api": "v4l2"
            }
        };
        const internal = AudioNodeModel.normalize(internalNode);
        const camera = AudioNodeModel.normalize(cameraNode);

        compare(internal.role, "specialized-node");
        compare(internal.specialization, "internal-audio");
        compare(camera.role, "non-audio");
        compare(AudioNodeModel.normalizedNodes([internalNode, cameraNode]).length, 1);
    }

    function test_nameFallbackIsExplicit() {
        const output = AudioNodeModel.normalize(node(30, 17, "bluez_output.headphones", {
            "media.class": "Audio/Sink"
        }));

        compare(output.role, "output-device");
        compare(output.classificationConfidence, "name-fallback");
    }

    function test_capabilitiesRequireReadinessAndNeverClaimRouteWrites() {
        const stream = node(40, 21, "Browser", {
            "media.class": "Stream/Output/Audio"
        });
        stream.ready = false;
        const record = AudioNodeModel.normalize(stream);

        verify(!record.capabilities.volumeRead);
        verify(!record.capabilities.volumeWrite);
        verify(!record.capabilities.preferredDefaultWrite);
        verify(!record.capabilities.routeRead);
        verify(!record.capabilities.routeWrite);
    }

    function test_safeProbeVolumeIsBoundedAndActuallyChanges() {
        compare(AudioNodeModel.safeProbeVolume(1), 0.95);
        compare(AudioNodeModel.safeProbeVolume(0.5), 0.45);
        compare(AudioNodeModel.safeProbeVolume(0), 0.05);
        compare(AudioNodeModel.safeProbeVolume(8), 0.95);
        compare(AudioNodeModel.safeProbeVolume(-8), 0.05);
    }

    function test_probeComparisonAllowsHardwareQuantization() {
        verify(AudioNodeModel.approximatelyEqual(0.499, 0.5, 0.002));
        verify(!AudioNodeModel.approximatelyEqual(0.49, 0.5, 0.002));
    }

    function test_applicationIdentityPrefersStableIdAndStripsDesktopSuffix() {
        const browserTabA = AudioNodeModel.normalize(node(50, 21, "Firefox tab A", {
            "application.id": "Org.Mozilla.firefox.desktop",
            "application.process.binary": "firefox-bin",
            "application.name": "Firefox"
        }));
        const browserTabB = AudioNodeModel.normalize(node(51, 21, "Firefox tab B", {
            "application.id": "org.mozilla.firefox",
            "application.name": "Different title"
        }));

        compare(browserTabA.applicationKey, "application-id:org.mozilla.firefox");
        compare(browserTabA.applicationIdentityKind, "application-id");
        compare(browserTabB.applicationKey, browserTabA.applicationKey);
    }

    function test_nativeFlatpakElectronAndGameIdentityFallbacks() {
        const flatpak = AudioNodeModel.normalize(node(52, 21, "Flatpak", {
            "application.id": "com.spotify.Client",
            "application.process.binary": "spotify"
        }));
        const electron = AudioNodeModel.normalize(node(53, 21, "Electron helper", {
            "application.process.binary": "discord",
            "application.name": "Discord Audio"
        }));
        const game = AudioNodeModel.normalize(node(54, 21, "Game stream", {
            "application.process.binary": "sample-game"
        }));

        compare(flatpak.applicationKey, "application-id:com.spotify.client");
        compare(electron.applicationKey, "binary:discord");
        compare(game.applicationKey, "binary:sample-game");
    }

    function test_displayFallbackIsBoundedAndPrivateMediaFieldsAreExcluded() {
        const longName = "A".repeat(300);
        const record = AudioNodeModel.normalize(node(55, 21, "Fallback", {
            "application.name": longName,
            "media.title": "private title",
            "media.filename": "/private/path/file.mp3",
            "object.serial": "9981"
        }));
        const serialized = JSON.stringify(record);

        compare(record.applicationIdentityKind, "display-fallback");
        compare(record.applicationKey.length, "display-fallback:".length + 160);
        compare(record.objectSerial, "9981");
        compare(record.sessionId, "pipewire-serial:9981");
        verify(!serialized.includes("private title"));
        verify(!serialized.includes("/private/path"));
    }

    function test_nonStreamVirtualNodeNeverGetsApplicationGroupingIdentity() {
        const effect = AudioNodeModel.normalize(node(56, 17, "easyeffects_sink", {
            "application.id": "com.github.wwmm.easyeffects",
            "node.virtual": "true"
        }));

        compare(effect.role, "specialized-node");
        compare(effect.applicationKey, "");
        compare(effect.applicationIdentityKind, "none");
    }

    function test_reconcilePreservesExistingRowsAndAppendsNewOnes() {
        const first = AudioNodeModel.normalizedNodes([node(20, 17, "alsa_output.second", {
                "media.class": "Audio/Sink",
                "device.api": "alsa"
            }), node(10, 17, "alsa_output.first", {
                "media.class": "Audio/Sink",
                "device.api": "alsa"
            })]);
        const refreshed = AudioNodeModel.normalizedNodes([node(5, 17, "alsa_output.new", {
                "media.class": "Audio/Sink",
                "device.api": "alsa"
            }), node(40, 17, "alsa_output.second", {
                "media.class": "Audio/Sink",
                "device.api": "alsa"
            }), node(30, 17, "alsa_output.first", {
                "media.class": "Audio/Sink",
                "device.api": "alsa"
            })]);
        const reconciled = AudioNodeModel.reconciledNodes(first, refreshed);

        compare(reconciled.map(record => record.name).join(","), "alsa_output.first,alsa_output.second,alsa_output.new");
        compare(reconciled.map(record => record.id).join(","), "30,40,5");
    }

    function test_reconcileDoesNotConflateDuplicateApplicationStreams() {
        const previous = AudioNodeModel.normalizedNodes([node(80, 21, "Browser", {
                "application.id": "browser",
                "object.serial": "800"
            }), node(81, 21, "Browser", {
                "application.id": "browser",
                "object.serial": "801"
            })]);
        const refreshed = AudioNodeModel.normalizedNodes([node(82, 21, "Browser", {
                "application.id": "browser",
                "object.serial": "801"
            }), node(83, 21, "Browser", {
                "application.id": "browser",
                "object.serial": "800"
            })]);
        const reconciled = AudioNodeModel.reconciledNodes(previous, refreshed);

        compare(reconciled.map(record => record.sessionId).join(","), "pipewire-serial:800,pipewire-serial:801");
        compare(reconciled.map(record => record.id).join(","), "83,82");
    }

    function test_reconcileCanRestoreOrderFromIdentityOnlyMemory() {
        const retained = [
            {
                stableKey: "output-device:alsa_output.first"
            },
            {
                stableKey: "input-device:alsa_input.second"
            }
        ];
        const reconnected = AudioNodeModel.normalizedNodes([node(5, 9, "alsa_input.second", {
                "media.class": "Audio/Source",
                "device.api": "alsa"
            }), node(20, 17, "alsa_output.first", {
                "media.class": "Audio/Sink",
                "device.api": "alsa"
            })]);
        const reconciled = AudioNodeModel.reconciledNodes(retained, reconnected);

        compare(reconciled.map(record => record.name).join(","), "alsa_output.first,alsa_input.second");
        compare(reconciled.map(record => record.id).join(","), "20,5");
    }
}
