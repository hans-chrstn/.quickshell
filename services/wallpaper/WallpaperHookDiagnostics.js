.pragma library

function derive(profileState, executorState, applicationState) {
    const profiles = Array.isArray(profileState?.hooks)
        ? profileState.hooks : []
    const runs = Array.isArray(executorState?.recentRuns)
        ? executorState.recentRuns : []
    const outcomes = {
        success: 0,
        failed: 0,
        timeout: 0,
        cancelled: 0,
        startFailed: 0
    }
    let resultCount = 0
    for (const run of runs) {
        for (const result of (run?.results || [])) {
            resultCount += 1
            switch (String(result?.outcome || "")) {
            case "success": outcomes.success += 1; break
            case "failed": outcomes.failed += 1; break
            case "timeout": outcomes.timeout += 1; break
            case "cancelled": outcomes.cancelled += 1; break
            case "start-failed": outcomes.startFailed += 1; break
            }
        }
    }
    const enabled = profiles.filter(profile => profile?.enabled === true)
    return {
        loaded: profileState?.loaded === true,
        profiles: {
            total: profiles.length,
            enabled: enabled.length,
            disabled: profiles.length - enabled.length,
            preChange: enabled.filter(profile =>
                profile.phase === "pre-change").length,
            postChange: enabled.filter(profile =>
                profile.phase === "post-change").length,
            global: enabled.filter(profile =>
                String(profile.screenName || "").length === 0).length,
            screenScoped: enabled.filter(profile =>
                String(profile.screenName || "").length > 0).length
        },
        execution: {
            running: executorState?.running === true,
            activeRunId: String(executorState?.activeRunId || ""),
            activeHookId: String(executorState?.activeHookId || ""),
            pendingCount: Math.max(0,
                Math.floor(Number(executorState?.pendingCount) || 0)),
            retainedBatches: runs.length,
            retainedResults: resultCount,
            outcomes: outcomes
        },
        application: {
            stage: String(applicationState?.hookStage || ""),
            runId: String(applicationState?.hookRunId || ""),
            changeCount: Math.max(0,
                Math.floor(Number(applicationState?.hookChangeCount) || 0)),
            reconcileQueued: applicationState?.reconcileQueued === true,
            staleBeforeApply: applicationState?.staleBeforeApply === true
        },
        error: String(profileState?.error || executorState?.error || "")
    }
}
