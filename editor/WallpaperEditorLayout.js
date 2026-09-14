.pragma library
.import "../components/layout/BoundedSplitModel.js" as Split

var defaultHorizontalWeights = [0.7, 6, 0.8]
var defaultVerticalWeights = [4, 1]

function finiteNumber(value, fallback) {
    const numeric = Number(value)
    return Number.isFinite(numeric) ? numeric : fallback
}

function policy(value) {
    const source = value || ({})
    return {
        outerMargin: Math.max(0, finiteNumber(source.outerMargin, 10)),
        gap: Math.max(0, finiteNumber(source.gap, 12)),
        headerHeight: Math.max(0, finiteNumber(source.headerHeight, 42)),
        compactThreshold: Math.max(1,
            finiteNumber(source.compactThreshold, 980)),
        fullHorizontalMinimums: Array.isArray(source.fullHorizontalMinimums)
            ? source.fullHorizontalMinimums : [210, 360, 240],
        compactHorizontalMinimums:
            Array.isArray(source.compactHorizontalMinimums)
            ? source.compactHorizontalMinimums : [156, 280, 180],
        verticalMinimums: Array.isArray(source.verticalMinimums)
            ? source.verticalMinimums : [220, 170]
    }
}

function resolve(options) {
    const source = options || ({})
    const rules = policy(source.policy)
    const width = Math.max(1, finiteNumber(source.width, 1))
    const height = Math.max(1, finiteNumber(source.height, 1))
    const innerWidth = Math.max(1, width - rules.outerMargin * 2)
    const belowHeaderHeight = Math.max(1, height - rules.outerMargin * 2
        - rules.headerHeight - rules.gap)
    const compact = width < rules.compactThreshold
    const horizontal = Split.resolve(innerWidth, rules.gap,
        compact ? rules.compactHorizontalMinimums
            : rules.fullHorizontalMinimums,
        source.horizontalWeights || defaultHorizontalWeights)
    const vertical = Split.resolve(belowHeaderHeight, rules.gap,
        rules.verticalMinimums,
        source.verticalWeights || defaultVerticalWeights)
    return {
        width: width,
        height: height,
        compact: compact,
        policy: rules,
        innerWidth: innerWidth,
        belowHeaderHeight: belowHeaderHeight,
        horizontal: horizontal,
        vertical: vertical,
        mediaWidth: horizontal.sizes[0],
        previewWidth: horizontal.sizes[1],
        inspectorWidth: horizontal.sizes[2],
        upperHeight: vertical.sizes[0],
        timelineHeight: vertical.sizes[1],
        overflowX: horizontal.overflow,
        overflowY: vertical.overflow,
        requiredWidth: horizontal.totalLength + rules.outerMargin * 2,
        requiredHeight: vertical.totalLength + rules.outerMargin * 2
            + rules.headerHeight + rules.gap
    }
}

function withLayouts(layout, horizontal, vertical) {
    return Object.assign({}, layout, {
        horizontal: horizontal,
        vertical: vertical,
        mediaWidth: horizontal.sizes[0],
        previewWidth: horizontal.sizes[1],
        inspectorWidth: horizontal.sizes[2],
        upperHeight: vertical.sizes[0],
        timelineHeight: vertical.sizes[1],
        overflowX: horizontal.overflow,
        overflowY: vertical.overflow
    })
}

function dragHorizontal(layout, dividerIndex, deltaX) {
    const result = Split.drag(layout?.horizontal, dividerIndex, deltaX)
    if (!result.accepted)
        return { accepted: false, error: result.error, layout: layout }
    return { accepted: true, error: "",
        layout: withLayouts(layout, result.layout, layout.vertical) }
}

function dragVertical(layout, deltaY) {
    const result = Split.drag(layout?.vertical, 0, deltaY)
    if (!result.accepted)
        return { accepted: false, error: result.error, layout: layout }
    return { accepted: true, error: "",
        layout: withLayouts(layout, layout.horizontal, result.layout) }
}

function preferences(layout) {
    return {
        horizontalWeights: (layout?.horizontal?.extraWeights
            || defaultHorizontalWeights).slice(),
        verticalWeights: (layout?.vertical?.extraWeights
            || defaultVerticalWeights).slice()
    }
}
