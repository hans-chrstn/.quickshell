.pragma library

function normalized(value) {
    return String(value || "").trim().toLowerCase();
}

function fuzzyScore(query, value) {
    const q = normalized(query);
    const text = normalized(value);
    if (!q.length || !text.length)
        return 0;
    if (text === q)
        return 1000;
    if (text.startsWith(q))
        return 800 - Math.min(200, text.length - q.length);
    const contained = text.indexOf(q);
    if (contained >= 0)
        return 600 - Math.min(200, contained * 8);

    let matched = 0;
    let first = -1;
    let previous = -2;
    let consecutive = 0;
    for (let i = 0; i < text.length && matched < q.length; ++i) {
        if (text[i] !== q[matched])
            continue;
        if (first < 0)
            first = i;
        if (i === previous + 1)
            consecutive++;
        previous = i;
        matched++;
    }
    return matched === q.length ? Math.max(1, 300 + consecutive * 12 - first * 3 - (text.length - q.length)) : 0;
}

function catalog(applications) {
    const entries = [];
    const seen = new Set();
    for (const app of applications || []) {
        if (!app || app.noDisplay || !app.id || seen.has(app.id))
            continue;
        seen.add(app.id);
        const actions = [];
        const availableActions = app.actions || [];
        for (let i = 0; i < availableActions.length; ++i) {
            const action = availableActions[i];
            if (action && action.id && action.name)
                actions.push({
                    id: action.id,
                    name: action.name,
                    icon: action.icon || "",
                    action: action
                });
        }
        entries.push({
            id: app.id,
            title: app.name || app.id,
            subtitle: app.genericName || app.comment || "",
            description: normalized(app.comment) === normalized(app.genericName) ? "" : app.comment || "",
            icon: app.icon || "application-x-executable",
            categories: app.categories || [],
            actions: actions,
            app: app,
            nameKey: normalized(app.name || app.id),
            genericKey: normalized(app.genericName),
            commentKey: normalized(app.comment),
            keywordsKey: normalized((app.keywords || []).join(" "))
        });
    }
    entries.sort((a, b) => a.title.localeCompare(b.title) || a.id.localeCompare(b.id));
    return entries;
}

function search(entries, query, limit) {
    const q = normalized(query);
    const found = [];
    for (const entry of entries || []) {
        const score = q.length === 0 ? 1 : Math.max(fuzzyScore(q, entry.nameKey), fuzzyScore(q, entry.genericKey) * 0.72, fuzzyScore(q, entry.commentKey) * 0.45, fuzzyScore(q, entry.keywordsKey) * 0.35);
        if (score > 0)
            found.push(Object.assign({}, entry, {
                score: score
            }));
    }
    found.sort((a, b) => b.score - a.score || a.title.localeCompare(b.title) || a.id.localeCompare(b.id));
    return found.slice(0, Math.max(0, limit));
}
