import QtQuick
import "AudioRoutePolicyModel.js" as AudioRoutePolicyModel

Item {
    id: root

    required property var policies
    required property var applications
    required property var targets
    required property int defaultOutputId
    required property int graphRevision
    required property var provider
    property var attemptedSignatures: ({})
    property int requestCount: 0
    property int acceptedCount: 0
    property int rejectedCount: 0
    property var lastDecision: null
    readonly property var plans: AudioRoutePolicyModel.reconciliationPlans(policies, applications, targets, defaultOutputId)

    visible: false
    width: 0
    height: 0

    function schedule() {
        reconcileTimer.restart();
    }

    function reconcile() {
        if (provider?.busy)
            return;
        for (const plan of plans) {
            if (plan.action === "none" || plan.signature.length === 0)
                continue;
            if (attemptedSignatures[plan.groupKey] === plan.signature)
                continue;
            const attempts = Object.assign({}, attemptedSignatures);
            attempts[plan.groupKey] = plan.signature;
            attemptedSignatures = attempts;
            const targetStableKey = plan.action === "fallback" ? "" : plan.targetStableKey;
            const origin = plan.action === "fallback" ? "policy-fallback" : "policy-apply";
            const result = provider.request(plan.groupKey, targetStableKey, origin);
            requestCount += 1;
            lastDecision = Object.assign({}, plan, {
                accepted: result.accepted === true,
                code: String(result.code || "")
            });
            if (result.accepted) {
                acceptedCount += 1;
                return;
            }
            rejectedCount += 1;
        }
    }

    function diagnostics() {
        return {
            policyCount: Object.keys(AudioRoutePolicyModel.normalizedPolicies(policies)).length,
            requestCount: requestCount,
            acceptedCount: acceptedCount,
            rejectedCount: rejectedCount,
            lastDecision: lastDecision,
            plans: plans
        };
    }

    onPoliciesChanged: schedule()
    onGraphRevisionChanged: schedule()
    onDefaultOutputIdChanged: schedule()
    Component.onCompleted: schedule()

    Connections {
        target: root.provider
        ignoreUnknownSignals: true

        function onBusyChanged() {
            if (target?.busy !== true)
                root.schedule();
        }
    }

    Timer {
        id: reconcileTimer

        interval: 0
        onTriggered: root.reconcile()
    }
}
