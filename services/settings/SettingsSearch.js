.pragma library

function normalized(value) {
    return String(value || "").toLocaleLowerCase().normalize("NFKD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-z0-9]+/g, " ").trim();
}

function subsequenceScore(text, token) {
    if (token.length < 4)
        return 0;
    let cursor = 0;
    let gaps = 0;
    for (let index = 0; index < text.length && cursor < token.length; ++index) {
        if (text[index] === token[cursor])
            cursor += 1;
        else if (cursor > 0)
            gaps += 1;
    }
    return cursor === token.length && gaps <= Math.max(2, Math.ceil(token.length * 0.4)) ? Math.max(1, 15 - gaps) : 0;
}

function fieldScore(text, token) {
    if (!text || !token)
        return 0;
    if (text === token)
        return 100;
    if (text.startsWith(token))
        return 75;
    if (text.split(" ").some(word => word.startsWith(token)))
        return 55;
    if (text.includes(token))
        return 35;
    return subsequenceScore(text, token);
}

function search(categories, query, limit) {
    const tokens = normalized(query).split(" ").filter(Boolean);
    if (tokens.length === 0)
        return [];
    const results = [];
    for (const category of categories || []) {
        for (const page of (category.subpages || []).concat(category.searchPages || [])) {
            const title = normalized(page.title);
            const description = normalized(page.desc);
            const keywords = normalized(page.keywords);
            const source = normalized(category.title + " " + (page.parentTitle || ""));
            let score = 0;
            for (const token of tokens) {
                const best = Math.max(fieldScore(title, token), Math.round(fieldScore(description, token) * 0.65), Math.round(fieldScore(keywords, token) * 0.7), Math.round(fieldScore(source, token) * 0.45));
                if (best === 0) {
                    score = 0;
                    break;
                }
                score += best;
            }
            if (score > 0)
                results.push({
                    id: page.id,
                    title: page.title,
                    description: page.desc || "",
                    categoryId: category.id,
                    categoryTitle: category.title + (page.parentTitle ? " › " + page.parentTitle : ""),
                    parentId: page.parentId || "",
                    score: score
                });
        }
    }
    results.sort((left, right) => right.score - left.score || left.title.localeCompare(right.title));
    return results.slice(0, Math.max(1, Math.min(50, Number(limit) || 20)));
}
