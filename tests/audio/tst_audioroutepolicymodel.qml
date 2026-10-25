import QtQuick
import QtTest
import "../../services/audio/AudioRoutePolicyModel.js" as AudioRoutePolicyModel

TestCase {
    name: "AudioRoutePolicyModel"

    function test_normalizesOnlyStableApplicationAndTargetIdentities() {
        const policies = AudioRoutePolicyModel.normalizedPolicies({
            "application-id:ORG.PLAYER.Desktop": {
                targetStableKey: "output-device:ALSA_OUTPUT.USB"
            },
            "binary:GAME": {
                targetStableKey: "specialized-node:EASYEFFECTS_SINK"
            },
            "display-fallback:browser": {
                targetStableKey: "output-device:speakers"
            },
            "application-id:broken": {
                targetStableKey: "pipewire-serial:99"
            },
            "binary:": {
                targetStableKey: "output-device:speakers"
            },
            "application-id:empty-target": {
                targetStableKey: "output-device:"
            }
        });

        compare(Object.keys(policies).length, 2);
        compare(policies["application-id:org.player.desktop"].targetStableKey, "output-device:alsa_output.usb");
        compare(policies["binary:game"].targetStableKey, "specialized-node:easyeffects_sink");
    }

    function test_updateAndClearAreImmutable() {
        const original = {
            "application-id:player": {
                targetStableKey: "output-device:speakers"
            }
        };
        const stored = AudioRoutePolicyModel.update(original, "binary:game", "output-device:headphones");

        verify(stored.accepted);
        compare(stored.code, "stored");
        compare(stored.policies["binary:game"].targetStableKey, "output-device:headphones");
        verify(original["binary:game"] === undefined);

        const cleared = AudioRoutePolicyModel.update(stored.policies, "application-id:player", "");
        verify(cleared.accepted);
        compare(cleared.code, "cleared");
        verify(cleared.policies["application-id:player"] === undefined);
        verify(stored.policies["application-id:player"] !== undefined);
    }

    function test_rejectsUnstableIdentitiesWithoutChangingPolicies() {
        const original = {
            "application-id:player": {
                targetStableKey: "output-device:speakers"
            }
        };
        const applicationFailure = AudioRoutePolicyModel.update(original, "display-fallback:Player", "output-device:headphones");
        const targetFailure = AudioRoutePolicyModel.update(original, "application-id:player", "pipewire-node:31");

        verify(!applicationFailure.accepted);
        compare(applicationFailure.code, "application-identity-unstable");
        verify(!targetFailure.accepted);
        compare(targetFailure.code, "target-identity-unstable");
        compare(applicationFailure.policies["application-id:player"].targetStableKey, "output-device:speakers");
        compare(targetFailure.policies["application-id:player"].targetStableKey, "output-device:speakers");
    }

    function test_lookupAndResetReturnDefensiveResults() {
        const original = {
            "application-id:player": {
                targetStableKey: "output-device:speakers"
            }
        };
        const policy = AudioRoutePolicyModel.policyFor(original, "APPLICATION-ID:PLAYER");
        policy.targetStableKey = "changed";
        compare(original["application-id:player"].targetStableKey, "output-device:speakers");

        const reset = AudioRoutePolicyModel.clear(original);
        compare(reset.removedCount, 1);
        compare(Object.keys(reset.policies).length, 0);
        compare(Object.keys(original).length, 1);
    }

    function test_policyCountIsBounded() {
        const oversized = ({});
        for (let index = 0; index < 140; index++)
            oversized["application-id:player-" + index] = {
                targetStableKey: "output-device:speakers"
            };

        const normalized = AudioRoutePolicyModel.normalizedPolicies(oversized);
        compare(Object.keys(normalized).length, 128);
        const result = AudioRoutePolicyModel.update(normalized, "application-id:new-player", "output-device:headphones");
        verify(!result.accepted);
        compare(result.code, "policy-limit");
    }

    function test_reconciliationPlansApplyCurrentAbsentAndFallbackStates() {
        const policies = {
            "application-id:current": {
                targetStableKey: "output-device:headphones"
            },
            "application-id:missing-app": {
                targetStableKey: "output-device:headphones"
            },
            "binary:fallback": {
                targetStableKey: "output-device:missing"
            }
        };
        const applications = {
            playing: [
                {
                    key: "playback-stream:application-id:current",
                    applicationKey: "application-id:current",
                    direction: "output",
                    active: true,
                    ready: true,
                    streamSessionIds: ["pipewire-serial:1"],
                    routeTargetIds: [31]
                },
                {
                    key: "playback-stream:binary:fallback",
                    applicationKey: "binary:fallback",
                    direction: "output",
                    active: true,
                    ready: true,
                    streamSessionIds: ["pipewire-serial:2"],
                    routeTargetIds: []
                }
            ]
        };
        const targets = [
            {
                id: 31,
                objectSerial: 301,
                stableKey: "output-device:headphones"
            }
        ];
        const plans = AudioRoutePolicyModel.reconciliationPlans(policies, applications, targets, 30);

        compare(plans.length, 3);
        compare(plans[0].state, "current");
        compare(plans[0].action, "none");
        compare(plans[1].state, "application-absent");
        compare(plans[2].state, "fallback-required");
        compare(plans[2].action, "fallback");
    }

    function test_reconciliationReappliesAfterStreamOrTargetIdentityChanges() {
        const policies = {
            "application-id:player": {
                targetStableKey: "specialized-node:effects"
            }
        };
        const applications = {
            playing: [
                {
                    key: "playback-stream:application-id:player",
                    applicationKey: "application-id:player",
                    direction: "output",
                    active: true,
                    ready: true,
                    streamSessionIds: ["pipewire-serial:9"],
                    routeTargetIds: [30]
                }
            ]
        };
        const first = AudioRoutePolicyModel.reconciliationPlans(policies, applications, [
            {
                id: 40,
                objectSerial: 400,
                stableKey: "specialized-node:effects"
            }
        ], 30)[0];
        const restarted = JSON.parse(JSON.stringify(applications));
        restarted.playing[0].streamSessionIds = ["pipewire-serial:10"];
        const second = AudioRoutePolicyModel.reconciliationPlans(policies, restarted, [
            {
                id: 41,
                objectSerial: 401,
                stableKey: "specialized-node:effects"
            }
        ], 30)[0];

        compare(first.action, "apply");
        compare(second.action, "apply");
        verify(first.signature !== second.signature);
    }

    function test_unavailableTargetDoesNotOverrideAnExistingFallbackRoute() {
        const plans = AudioRoutePolicyModel.reconciliationPlans({
            "application-id:player": {
                targetStableKey: "output-device:missing"
            }
        }, {
            playing: [
                {
                    key: "playback-stream:application-id:player",
                    applicationKey: "application-id:player",
                    direction: "output",
                    active: true,
                    ready: true,
                    streamSessionIds: ["pipewire-serial:1"],
                    routeTargetIds: [30]
                }
            ]
        }, [], 30);

        compare(plans[0].state, "target-unavailable");
        compare(plans[0].action, "none");
    }
}
