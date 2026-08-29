pragma Singleton

import QtQuick
import Quickshell
import qs.services.config
import "LifecyclePolicy.js" as LifecyclePolicy

Singleton {
    id: root

    property var resources: ({})
    readonly property bool adaptiveEnabled:
        ConfigService.adaptiveLifecycleEnabled
    property bool rebalanceScheduled: false
    readonly property real inactiveBudgetUnits: 100
    readonly property var policy: ({
        recencyHalfLifeMs: 120000,
        frequencyHalfLifeMs: 900000,
        priorityWeight: 1,
        recencyWeight: 60,
        frequencyWeight: 20,
        costWeight: 0.25
    })

    signal evictionRequested(string resourceId, string reason)

    function emptyRecord(resourceId) {
        return {
            resourceId: String(resourceId || ""),
            owner: "",
            restorationSource: "",
            classification: "active-only",
            adaptiveEligible: false,
            estimatedCostUnits: 0,
            basePriority: 0,
            evictionPending: false,
            registered: false,
            requested: false,
            active: false,
            loaded: false,
            registeredAtMs: 0,
            lastUsedMs: 0,
            frequencyScore: 0,
            frequencyUpdatedAtMs: 0,
            activeSinceMs: 0,
            activeDurationMs: 0,
            requestStartedAtMs: 0,
            lastLoadedAtMs: 0,
            lastLoadDurationMs: 0,
            maximumLoadDurationMs: 0,
            totalLoadDurationMs: 0,
            averageLoadDurationMs: 0,
            loadCount: 0,
            unloadCount: 0,
            registrationCount: 0,
            retentionReason: "",
            evictionReason: "",
            error: ""
        }
    }

    function publish(resourceId, record) {
        const updated = Object.assign({}, resources)
        updated[resourceId] = record
        resources = updated
        scheduleRebalance()
    }

    function scheduleRebalance() {
        if (!adaptiveEnabled || rebalanceScheduled)
            return
        rebalanceScheduled = true
        Qt.callLater(rebalance)
    }

    function rebalance() {
        rebalanceScheduled = false
        if (!adaptiveEnabled)
            return
        const now = Date.now()
        const records = Object.keys(resources).map(id => resources[id])
        const plan = LifecyclePolicy.buildPlan(
            records, inactiveBudgetUnits, now, policy)
        for (let index = 0; index < plan.evicted.length; ++index) {
            const id = plan.evicted[index].resourceId
            const previous = resources[id]
            if (!previous || previous.evictionPending || previous.active
                    || !previous.loaded || !previous.requested)
                continue
            publish(id, Object.assign({}, previous, {
                evictionPending: true,
                evictionReason: "inactive-budget-pressure"
            }))
            evictionRequested(id, "inactive-budget-pressure")
        }
    }

    onAdaptiveEnabledChanged: {
        if (adaptiveEnabled)
            scheduleRebalance()
        else
            rebalanceScheduled = false
    }

    function registerResource(resourceId, owner, classification) {
        const id = String(resourceId || "").trim()
        if (id.length === 0)
            return false

        const previous = resources[id] || emptyRecord(id)
        if (previous.registered) {
            publish(id, Object.assign({}, previous, {
                error: "A lifecycle resource with this ID is already registered"
            }))
            return false
        }

        const now = Date.now()
        publish(id, Object.assign({}, previous, {
            owner: String(owner || ""),
            classification: String(classification || "active-only"),
            registered: true,
            registeredAtMs: now,
            registrationCount: (Number(previous.registrationCount) || 0) + 1,
            retentionReason: "registered",
            evictionReason: "",
            error: ""
        }))
        return true
    }

    function configureResource(resourceId, adaptiveEligible,
            estimatedCostUnits, basePriority, restorationSource) {
        const id = String(resourceId || "")
        const previous = resources[id]
        if (!previous?.registered)
            return false
        publish(id, Object.assign({}, previous, {
            adaptiveEligible: Boolean(adaptiveEligible),
            estimatedCostUnits: Math.max(0,
                Number(estimatedCostUnits) || 0),
            basePriority: Number(basePriority) || 0,
            restorationSource: String(restorationSource || "").trim()
        }))
        return true
    }

    function closeActiveInterval(record, now) {
        let duration = Number(record.activeDurationMs) || 0
        const since = Number(record.activeSinceMs) || 0
        if (record.active && since > 0)
            duration += Math.max(0, now - since)
        return duration
    }

    function setRequested(resourceId, requested, retentionReason,
            evictionReason) {
        const id = String(resourceId || "")
        const previous = resources[id]
        if (!previous?.registered)
            return false

        const now = Date.now()
        const nextRequested = Boolean(requested)

        publish(id, Object.assign({}, previous, {
            requested: nextRequested,
            evictionPending: nextRequested
                ? previous.evictionPending : false,
            requestStartedAtMs: !previous.requested && nextRequested
                ? now : previous.requestStartedAtMs,
            retentionReason: String(retentionReason || ""),
            evictionReason: String(evictionReason || ""),
            error: ""
        }))
        return true
    }

    function setActive(resourceId, active) {
        const id = String(resourceId || "")
        const previous = resources[id]
        if (!previous?.registered)
            return false

        const nextActive = Boolean(active)
        if (nextActive === previous.active)
            return true
        const now = Date.now()
        let duration = Number(previous.activeDurationMs) || 0
        let activeSince = Number(previous.activeSinceMs) || 0
        let frequency = LifecyclePolicy.frequencyAt(previous, now, policy)
        if (previous.active && !nextActive) {
            duration = closeActiveInterval(previous, now)
            activeSince = 0
        } else if (!previous.active && nextActive) {
            activeSince = now
            frequency += 1
        }

        publish(id, Object.assign({}, previous, {
            active: nextActive,
            evictionPending: nextActive ? false : previous.evictionPending,
            lastUsedMs: nextActive ? now : previous.lastUsedMs,
            frequencyScore: frequency,
            frequencyUpdatedAtMs: now,
            activeSinceMs: activeSince,
            activeDurationMs: duration,
            error: ""
        }))
        return true
    }

    function setLoaded(resourceId, loaded) {
        const id = String(resourceId || "")
        const previous = resources[id]
        if (!previous?.registered)
            return false
        const nextLoaded = Boolean(loaded)
        if (nextLoaded === previous.loaded)
            return true
        const now = Date.now()
        const loadDuration = nextLoaded
            && Number(previous.requestStartedAtMs) > 0
            ? Math.max(0, now - Number(previous.requestStartedAtMs)) : 0
        const loadCount = (Number(previous.loadCount) || 0)
            + (nextLoaded ? 1 : 0)
        const totalLoadDuration = (Number(previous.totalLoadDurationMs) || 0)
            + (nextLoaded ? loadDuration : 0)
        publish(id, Object.assign({}, previous, {
            loaded: nextLoaded,
            evictionPending: nextLoaded ? previous.evictionPending : false,
            loadCount: loadCount,
            unloadCount: (Number(previous.unloadCount) || 0)
                + (nextLoaded ? 0 : 1),
            lastLoadedAtMs: nextLoaded ? now : previous.lastLoadedAtMs,
            lastLoadDurationMs: nextLoaded
                ? loadDuration : previous.lastLoadDurationMs,
            maximumLoadDurationMs: nextLoaded
                ? Math.max(Number(previous.maximumLoadDurationMs) || 0,
                    loadDuration)
                : Number(previous.maximumLoadDurationMs) || 0,
            totalLoadDurationMs: totalLoadDuration,
            averageLoadDurationMs: loadCount > 0
                ? totalLoadDuration / loadCount : 0
        }))
        return true
    }

    function unregisterResource(resourceId, reason) {
        const id = String(resourceId || "")
        const previous = resources[id]
        if (!previous?.registered)
            return false
        const now = Date.now()
        publish(id, Object.assign({}, previous, {
            registered: false,
            requested: false,
            active: false,
            loaded: false,
            evictionPending: false,
            activeSinceMs: 0,
            requestStartedAtMs: 0,
            activeDurationMs: closeActiveInterval(previous, now),
            unloadCount: (Number(previous.unloadCount) || 0)
                + (previous.loaded ? 1 : 0),
            retentionReason: "",
            evictionReason: String(reason || "owner-destroyed")
        }))
        return true
    }

    function recordFor(resourceId) {
        const id = String(resourceId || "")
        return snapshotRecord(resources[id] || emptyRecord(id), Date.now())
    }

    function snapshotRecord(record, now) {
        const result = Object.assign({}, record)
        result.activeDurationMs = closeActiveInterval(record, now)
        return result
    }

    function snapshot() {
        const now = Date.now()
        const result = ({})
        for (const id in resources)
            result[id] = snapshotRecord(resources[id], now)
        const budgetPlan = LifecyclePolicy.buildPlan(
            Object.keys(result).map(id => result[id]),
            inactiveBudgetUnits, now, policy)
        return {
            capturedAtMs: now,
            sessionLocal: true,
            collection: "event-driven",
            adaptivePolicy: {
                enabled: adaptiveEnabled,
                mode: adaptiveEnabled ? "enforcing" : "preview-only",
                policy: policy,
                plan: budgetPlan
            },
            contractWarnings: LifecyclePolicy.contractWarnings(
                Object.keys(result).map(id => result[id])),
            resourceCount: Object.keys(result).length,
            resources: result
        }
    }
}
