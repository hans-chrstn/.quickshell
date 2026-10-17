function run(frameRate, durationMs, observedFrames, elapsedMs) {
    const fps = Math.max(0, Number(frameRate) || 0)
    const duration = Math.max(0, Number(durationMs) || 0)
    const elapsed = Math.max(0, Number(elapsedMs) || 0)
    const expected = Math.max(0, Math.round(fps * duration / 1000))
    const observed = Math.max(0, Math.round(Number(observedFrames) || 0))
    const timingValid = elapsed >= duration * 0.8
        && elapsed <= duration * 1.5
    const cappedObserved = Math.min(expected, observed)
    const dropped = expected > 0 ? Math.max(0, expected - cappedObserved) : 0
    return {
        valid: timingValid && expected > 0,
        expectedFrames: expected,
        observedFrames: observed,
        droppedFrames: dropped,
        droppedFrameRatio: expected > 0 ? dropped / expected : null,
        elapsedMs: elapsed,
        error: timingValid ? (expected > 0 ? "" : "Expected frame count is unavailable")
            : "Playback measurement was interrupted or delayed"
    }
}

function aggregate(runs) {
    const accepted = (runs || []).filter(value => value && value.valid)
    let expected = 0
    let observed = 0
    let dropped = 0
    for (const value of accepted) {
        expected += Math.max(0, Number(value.expectedFrames) || 0)
        observed += Math.max(0, Number(value.observedFrames) || 0)
        dropped += Math.max(0, Number(value.droppedFrames) || 0)
    }
    return {
        validRuns: accepted.length,
        expectedFrames: expected,
        observedFrames: observed,
        droppedFrames: dropped,
        droppedFrameRatio: expected > 0 ? dropped / expected : null
    }
}
