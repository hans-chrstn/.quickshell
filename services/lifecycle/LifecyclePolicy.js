.pragma library

function finiteNumber(value, fallback) {
    const numeric = Number(value)
    return Number.isFinite(numeric) ? numeric : fallback
}

function decayedValue(value, elapsedMs, halfLifeMs) {
    const initial = Math.max(0, finiteNumber(value, 0))
    const elapsed = Math.max(0, finiteNumber(elapsedMs, 0))
    const halfLife = Math.max(1, finiteNumber(halfLifeMs, 1))
    return initial * Math.pow(0.5, elapsed / halfLife)
}

function frequencyAt(record, nowMs, policy) {
    const updatedAt = finiteNumber(record.frequencyUpdatedAtMs, nowMs)
    return decayedValue(record.frequencyScore,
        Math.max(0, nowMs - updatedAt), policy.frequencyHalfLifeMs)
}

function retentionScore(record, nowMs, policy) {
    const lastUsed = finiteNumber(record.lastUsedMs, 0)
    const age = lastUsed > 0 ? Math.max(0, nowMs - lastUsed) : nowMs
    const recency = lastUsed > 0
        ? decayedValue(1, age, policy.recencyHalfLifeMs) : 0
    const frequency = frequencyAt(record, nowMs, policy)
    const priority = finiteNumber(record.basePriority, 0)
    const cost = Math.max(0, finiteNumber(record.estimatedCostUnits, 0))
    return priority * policy.priorityWeight
        + recency * policy.recencyWeight
        + frequency * policy.frequencyWeight
        - cost * policy.costWeight
}

function isCandidate(record) {
    return Boolean(record.registered && record.loaded && record.requested
        && !record.active && record.adaptiveEligible
        && record.classification !== "pinned")
}

function contractWarnings(records) {
    const allowed = ["pinned", "active-only", "briefly-warm",
        "expensive", "explicitly-cacheable"]
    const warnings = []
    for (let index = 0; index < records.length; ++index) {
        const record = records[index]
        const id = String(record.resourceId || "")
        if (!record.registered)
            continue
        if (String(record.owner || "").trim().length === 0)
            warnings.push({ resourceId: id, issue: "missing-owner" })
        if (String(record.restorationSource || "").trim().length === 0)
            warnings.push({
                resourceId: id, issue: "missing-restoration-source"
            })
        if (allowed.indexOf(record.classification) < 0)
            warnings.push({
                resourceId: id, issue: "invalid-classification"
            })
        if (record.adaptiveEligible && record.classification === "pinned")
            warnings.push({
                resourceId: id, issue: "pinned-resource-is-eligible"
            })
        if (record.adaptiveEligible
                && finiteNumber(record.estimatedCostUnits, 0) <= 0)
            warnings.push({
                resourceId: id, issue: "eligible-resource-has-no-cost"
            })
    }
    return warnings
}

function buildPlan(records, budgetUnits, nowMs, policy) {
    const budget = Math.max(0, finiteNumber(budgetUnits, 0))
    const candidates = []
    for (let index = 0; index < records.length; ++index) {
        const record = records[index]
        if (!isCandidate(record))
            continue
        candidates.push({
            resourceId: String(record.resourceId || ""),
            estimatedCostUnits: Math.max(0,
                finiteNumber(record.estimatedCostUnits, 0)),
            score: retentionScore(record, nowMs, policy),
            decayedFrequency: frequencyAt(record, nowMs, policy)
        })
    }

    candidates.sort(function(left, right) {
        if (left.score !== right.score)
            return right.score - left.score
        return left.resourceId.localeCompare(right.resourceId)
    })

    let used = 0
    const retained = []
    const evicted = []
    for (let index = 0; index < candidates.length; ++index) {
        const candidate = candidates[index]
        if (used + candidate.estimatedCostUnits <= budget) {
            retained.push(candidate)
            used += candidate.estimatedCostUnits
        } else {
            evicted.push(candidate)
        }
    }

    return {
        budgetUnits: budget,
        usedUnits: used,
        remainingUnits: Math.max(0, budget - used),
        candidateCount: candidates.length,
        retained: retained,
        evicted: evicted
    }
}
