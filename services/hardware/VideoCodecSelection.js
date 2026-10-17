function acceptedCandidate(evaluations) {
    const accepted = (evaluations || []).filter(candidate =>
        candidate && candidate.measurementAccepted === true
            && String(candidate.codec || "").length > 0
            && String(candidate.encoder || "").length > 0)
    accepted.sort((left, right) => {
        const leftDrops = Number(left.evidence?.droppedFrameRatio)
        const rightDrops = Number(right.evidence?.droppedFrameRatio)
        const dropDifference = (Number.isFinite(leftDrops) ? leftDrops : 1)
            - (Number.isFinite(rightDrops) ? rightDrops : 1)
        if (Math.abs(dropDifference) > 0.000001)
            return dropDifference
        const leftEncode = Number(left.evidence?.encodeElapsedMs)
        const rightEncode = Number(right.evidence?.encodeElapsedMs)
        const encodeDifference = (Number.isFinite(leftEncode)
            ? leftEncode : Number.MAX_VALUE) - (Number.isFinite(rightEncode)
            ? rightEncode : Number.MAX_VALUE)
        if (encodeDifference !== 0)
            return encodeDifference
        return String(left.codec).localeCompare(String(right.codec))
    })
    return accepted.length > 0 ? accepted[0] : null
}

function conservativeCandidate(candidates) {
    for (const candidate of candidates || []) {
        if (String(candidate?.codec || "") === "h264"
                && String(candidate?.encoder || "") === "libx264")
            return Object.assign({}, candidate, {
                selectionReason: "conservative-fallback"
            })
    }
    return {
        codec: "h264",
        encoder: "libx264",
        measurementAccepted: false,
        selectionReason: "conservative-fallback"
    }
}

function select(evaluations, candidates) {
    const measured = acceptedCandidate(evaluations)
    return measured ? Object.assign({}, measured, {
        selectionReason: "accepted-runtime-evidence"
    }) : conservativeCandidate(candidates)
}
