.pragma library

.import "WallpaperProjectModel.js" as ProjectModel
.import "../WallpaperRenderSupport.js" as RenderSupport

function availabilityByAsset(diagnostics) {
    const records = ({})
    for (const record of diagnostics?.assets || [])
        records[String(record?.assetId || "")] = record
    return records
}

function assetPlans(project, diagnostics) {
    const availability = availabilityByAsset(diagnostics)
    return project.assets.map(asset => {
        const resolved = availability[asset.id] || ({ state: "pending" })
        const media = resolved.media || null
        const backend = resolved.state === "available"
            ? RenderSupport.rendererFor(media) : ""
        const state = resolved.state !== "available"
            ? String(resolved.state || "pending")
            : backend.length > 0 ? "ready" : "unsupported"
        return {
            id: asset.id,
            name: asset.name,
            declaredKind: asset.kind,
            state: state,
            path: state === "ready" ? String(resolved.resolvedPath || "") : "",
            media: state === "ready" ? media : null,
            backend: backend,
            error: state === "unsupported"
                ? String(resolved.error || "No accepted renderer for this media")
                : String(resolved.error || "")
        }
    })
}

function build(document, diagnostics) {
    const parsed = ProjectModel.parse(document)
    if (!parsed.accepted)
        return { accepted: false, error: parsed.error, plan: null }
    const project = parsed.document.project
    if (!diagnostics || diagnostics.projectId !== project.id)
        return { accepted: false,
            error: "Availability does not match project: " + project.id,
            plan: null }

    const assets = assetPlans(project, diagnostics)
    const byId = ({})
    for (const asset of assets) byId[asset.id] = asset
    const clips = []
    const blockedClips = []
    let derivedDurationMs = 0
    for (let trackIndex = 0; trackIndex < project.tracks.length; ++trackIndex) {
        const track = project.tracks[trackIndex]
        if (!track.enabled || track.type !== "media") continue
        for (let clipIndex = 0; clipIndex < track.clips.length; ++clipIndex) {
            const clip = track.clips[clipIndex]
            if (!clip.enabled) continue
            const asset = byId[clip.assetId]
            const endMs = Math.min(
                project.durationMs > 0
                    ? project.durationMs
                    : ProjectModel.maximumProjectDurationMs,
                clip.startMs + clip.durationMs)
            if (endMs <= clip.startMs) continue
            derivedDurationMs = Math.max(derivedDurationMs, endMs)
            const entry = {
                id: clip.id,
                trackId: track.id,
                trackIndex: trackIndex,
                clipIndex: clipIndex,
                assetId: clip.assetId,
                startMs: clip.startMs,
                endMs: endMs,
                durationMs: endMs - clip.startMs,
                sourceInMs: clip.sourceInMs,
                loop: clip.loop,
                path: asset?.path || "",
                media: asset?.media || null,
                backend: asset?.backend || "",
                fit: "cover"
            }
            if (asset?.state === "ready") clips.push(entry)
            else blockedClips.push(Object.assign({}, entry, {
                state: asset?.state || "missing",
                error: asset?.error || "Asset is unavailable"
            }))
        }
    }
    clips.sort((left, right) => left.startMs - right.startMs
        || left.trackIndex - right.trackIndex
        || left.clipIndex - right.clipIndex
        || left.id.localeCompare(right.id))
    blockedClips.sort((left, right) => left.startMs - right.startMs
        || left.trackIndex - right.trackIndex
        || left.clipIndex - right.clipIndex
        || left.id.localeCompare(right.id))
    return { accepted: true, error: "", plan: {
        projectId: project.id,
        name: project.name,
        durationMs: project.durationMs > 0
            ? project.durationMs : derivedDurationMs,
        assets: assets,
        clips: clips,
        blockedClips: blockedClips,
        outputTargets: project.outputTargets,
        runtimeRequirements: project.runtimeRequirements,
        ready: diagnostics.complete === true && blockedClips.length === 0
    } }
}

function frameAt(plan, positionMs) {
    if (!plan || typeof plan !== "object") return []
    const duration = Number(plan.durationMs || 0)
    const requested = Number(positionMs || 0)
    if (duration <= 0 || requested >= duration) return []
    const position = Math.max(0, requested)
    return (plan.clips || []).filter(clip =>
        position >= clip.startMs && position < clip.endMs)
}

function outputForScreen(plan, screenName) {
    if (!plan || typeof plan !== "object") return null
    const name = String(screenName || "")
    const outputs = plan.outputTargets || []
    return outputs.find(output => output.screenName === name)
        || outputs.find(output => output.screenName.length === 0)
        || null
}

function frameForScreen(plan, positionMs, screenName) {
    const output = outputForScreen(plan, screenName)
    const fit = output?.fit || "cover"
    return frameAt(plan, positionMs).map(clip =>
        Object.assign({}, clip, { fit: fit, outputId: output?.id || "" }))
}
