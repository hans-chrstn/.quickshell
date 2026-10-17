.pragma library

var maximumScreens = 32

function pathsForPlans(plans, limit) {
    const source = plans && typeof plans === "object" ? plans : ({})
    const boundedLimit = Math.max(0, Math.min(maximumScreens,
        Math.floor(Number(limit) || maximumScreens)))
    const paths = ({})
    let retained = 0
    for (const rawName in source) {
        if (retained >= boundedLimit)
            break
        const name = String(rawName || "").trim().slice(0, 128)
        const plan = source[rawName]
        const path = String(plan?.path || "").trim()
        if (name.length === 0 || plan?.state !== "ready"
                || path.length === 0 || paths[name] !== undefined)
            continue
        paths[name] = path
        ++retained
    }
    return paths
}
