import QtQuick
import QtTest
import "../../services/lifecycle/LifecyclePolicy.js" as LifecyclePolicy

TestCase {
    name: "LifecyclePolicy"

    readonly property var policy: ({
        recencyHalfLifeMs: 1000,
        frequencyHalfLifeMs: 4000,
        priorityWeight: 1,
        recencyWeight: 60,
        frequencyWeight: 20,
        costWeight: 0.25
    })

    function record(id, overrides) {
        return Object.assign({
            resourceId: id,
            registered: true,
            loaded: true,
            requested: true,
            active: false,
            adaptiveEligible: true,
            classification: "briefly-warm",
            lastUsedMs: 9000,
            frequencyScore: 1,
            frequencyUpdatedAtMs: 9000,
            estimatedCostUnits: 40,
            basePriority: 0
        }, overrides || {})
    }

    function test_emptyCandidateSet() {
        const plan = LifecyclePolicy.buildPlan([], 100, 10000, policy)
        compare(plan.candidateCount, 0)
        compare(plan.usedUnits, 0)
    }

    function test_activePinnedAndIneligibleAreProtected() {
        const records = [
            record("active", { active: true }),
            record("pinned", { classification: "pinned" }),
            record("ineligible", { adaptiveEligible: false })
        ]
        compare(LifecyclePolicy.buildPlan(records, 100, 10000, policy)
            .candidateCount, 0)
    }

    function test_recencyAndFrequencyDecay() {
        const recent = record("recent", { lastUsedMs: 9900 })
        const frequentOld = record("frequent-old", {
            lastUsedMs: 5000,
            frequencyScore: 12,
            frequencyUpdatedAtMs: 5000
        })
        const plan = LifecyclePolicy.buildPlan(
            [recent, frequentOld], 40, 10000, policy)
        compare(plan.retained.length, 1)
        compare(plan.evicted.length, 1)
        compare(plan.retained[0].resourceId, "frequent-old")

        const muchLater = LifecyclePolicy.buildPlan(
            [recent, frequentOld], 40, 30000, policy)
        verify(muchLater.retained[0].decayedFrequency
            < plan.retained[0].decayedFrequency)
    }

    function test_costAndPriorityAffectOrder() {
        const cheap = record("cheap", { estimatedCostUnits: 20 })
        const expensive = record("expensive", { estimatedCostUnits: 80 })
        const prioritized = record("prioritized", {
            estimatedCostUnits: 20,
            basePriority: 25
        })
        const plan = LifecyclePolicy.buildPlan(
            [expensive, cheap, prioritized], 40, 10000, policy)
        compare(plan.retained.length, 2)
        compare(plan.retained[0].resourceId, "prioritized")
        compare(plan.retained[1].resourceId, "cheap")
        compare(plan.evicted[0].resourceId, "expensive")
    }

    function test_deterministicTieBreak() {
        const plan = LifecyclePolicy.buildPlan(
            [record("zeta"), record("alpha")], 40, 10000, policy)
        compare(plan.retained[0].resourceId, "alpha")
        compare(plan.evicted[0].resourceId, "zeta")
    }

    function test_contractAuditAcceptsCompleteBoundary() {
        const complete = record("complete", {
            owner: "test-owner",
            restorationSource: "test-state",
            estimatedCostUnits: 20
        })
        compare(LifecyclePolicy.contractWarnings([complete]).length, 0)
    }

    function test_contractAuditReportsUnsafeBoundary() {
        const unsafe = record("unsafe", {
            owner: "",
            restorationSource: "",
            classification: "pinned",
            estimatedCostUnits: 0
        })
        const issues = LifecyclePolicy.contractWarnings([unsafe])
            .map(entry => entry.issue).sort()
        compare(issues.join(","), [
            "eligible-resource-has-no-cost",
            "missing-owner",
            "missing-restoration-source",
            "pinned-resource-is-eligible"
        ].join(","))
    }
}
