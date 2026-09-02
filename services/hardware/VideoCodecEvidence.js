const policyVersion = 1

function finiteNumber(value, fallback) {
    const number = Number(value)
    return Number.isFinite(number) ? number : fallback
}

function requirements() {
    return {
        version: policyVersion,
        minimumRuns: 3,
        minimumPlaybackMs: 15000,
        maximumDroppedFrameRatio: 0.01,
        requireEncodeSuccess: true,
        requireQtPlaybackSuccess: true,
        requireHardwareDecodeProof: true,
        requireHardwareTextureProof: true
    }
}

function recordFor(evidence, codec) {
    const source = evidence && evidence[codec] ? evidence[codec] : ({})
    return {
        runs: Math.max(0, Math.floor(finiteNumber(source.runs, 0))),
        playbackMs: Math.max(0, finiteNumber(source.playbackMs, 0)),
        encodeSucceeded: source.encodeSucceeded === true,
        qtPlaybackSucceeded: source.qtPlaybackSucceeded === true,
        hardwareDecodeVerified: source.hardwareDecodeVerified === true,
        hardwareTexturesVerified: source.hardwareTexturesVerified === true,
        encodeElapsedMs: Math.max(0,
            finiteNumber(source.encodeElapsedMs, 0)),
        droppedFrameRatio: source.droppedFrameRatio === undefined
                || source.droppedFrameRatio === null
            ? null : Math.max(0, finiteNumber(source.droppedFrameRatio, 1))
    }
}

function fromBenchmarkRecords(records) {
    const evidence = ({})
    for (const record of records || []) {
        const codec = String(record?.codec || "").toLowerCase()
        if (codec.length === 0)
            continue
        evidence[codec] = {
            runs: Math.max(0, Number(record.playbackRuns) || 0),
            playbackMs: Math.max(0, Number(record.playbackMs) || 0),
            encodeSucceeded: record.encodeSucceeded === true,
            encodeElapsedMs: Math.max(0,
                Number(record.encodeElapsedMs) || 0),
            qtPlaybackSucceeded: record.qtPlaybackSucceeded === true,
            hardwareDecodeVerified:
                record.hardwareDecodeVerified === true,
            hardwareTexturesVerified:
                record.hardwareTexturesVerified === true,
            droppedFrameRatio: record.droppedFrameRatio === undefined
                ? null : record.droppedFrameRatio
        }
    }
    return evidence
}

function evaluateCandidate(candidate, evidence) {
    const codec = String(candidate && candidate.codec || "")
    const record = recordFor(evidence, codec)
    const required = requirements()
    const missing = []

    if (!candidate || candidate.benchmarkable !== true)
        return Object.assign({}, candidate || ({}), {
            measurementState: "unavailable",
            measurementAccepted: false,
            missingEvidence: ["benchmarkable codec candidate"],
            evidence: record
        })

    if (record.runs < required.minimumRuns)
        missing.push("three comparable runs")
    if (record.playbackMs < required.minimumPlaybackMs)
        missing.push("15 seconds of Qt playback")
    if (!record.encodeSucceeded)
        missing.push("successful bounded encode")
    if (!record.qtPlaybackSucceeded)
        missing.push("successful Qt Multimedia playback")
    if (!record.hardwareDecodeVerified)
        missing.push("verified hardware decode")
    if (!record.hardwareTexturesVerified)
        missing.push("verified GPU-backed video textures")
    if (record.droppedFrameRatio === null)
        missing.push("observed dropped-frame ratio")
    else if (record.droppedFrameRatio > required.maximumDroppedFrameRatio)
        missing.push("dropped-frame ratio at or below 1%")

    return Object.assign({}, candidate, {
        measurementState: missing.length === 0 ? "accepted" : "incomplete",
        measurementAccepted: missing.length === 0,
        missingEvidence: missing,
        evidence: record
    })
}

function evaluateCandidates(candidates, evidence) {
    return (candidates || []).map(candidate =>
        evaluateCandidate(candidate, evidence || ({})))
}

function automaticSelectionReady(evaluations) {
    return (evaluations || []).some(candidate =>
        candidate.measurementAccepted === true)
}
