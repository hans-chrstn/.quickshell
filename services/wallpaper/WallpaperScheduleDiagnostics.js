.pragma library

function normalizedNames(values) {
    const result = []
    for (const value of values || []) {
        const name = String(value || "").trim().slice(0, 128)
        if (name.length > 0 && result.indexOf(name) < 0)
            result.push(name)
    }
    return result
}

function derive(screenNames, plans, rulePlans, overrides) {
    const names = normalizedNames(screenNames)
    const playlistPlans = plans || ({})
    const temporalPlans = rulePlans || ({})
    const override = overrides || ({})
    const scoped = override.screens || ({})
    const outputs = ({})
    let suppressedCount = 0
    let plannedCount = 0
    let waitingCount = 0

    for (const name of names) {
        const suppressed = override.global === true || scoped[name] === true
        const plan = playlistPlans[name] || null
        const rulePlan = temporalPlans[name] || null
        const waiting = !suppressed && !plan
            && Number(rulePlan?.nextAtMs) > 0
        const state = suppressed ? "manual-suppressed"
            : plan ? "scheduled" : waiting ? "waiting-for-rule" : "idle"
        if (suppressed)
            suppressedCount += 1
        else if (plan)
            plannedCount += 1
        else if (waiting)
            waitingCount += 1
        outputs[name] = {
            state: state,
            manualSuppressed: suppressed,
            selectionSource: String(plan?.selectionSource
                || rulePlan?.effectiveSource || ""),
            playlistId: String(plan?.playlistId
                || rulePlan?.effectivePlaylistId || ""),
            timeRuleId: String(plan?.timeRuleId
                || rulePlan?.activeRuleId || ""),
            entryId: String(plan?.entryId || ""),
            path: String(plan?.path || ""),
            nextPlaylistAtMs: Number(plan?.nextAtMs) || 0,
            nextRuleAtMs: Number(rulePlan?.nextAtMs) || 0
        }
    }

    return {
        connectedCount: names.length,
        eligibleCount: names.length - suppressedCount,
        suppressedCount: suppressedCount,
        plannedCount: plannedCount,
        waitingCount: waitingCount,
        outputs: outputs
    }
}
