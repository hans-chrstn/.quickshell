pragma Singleton

import QtQuick
import Quickshell
import qs.core

LauncherProvider {
    id: root

    providerId: "desktop-apps"

    readonly property var applications: DesktopEntries.applications.values

    function fuzzyScore(query, text) {
        const q = query.trim().toLowerCase()
        const value = String(text || "").toLowerCase()

        if (q.length === 0)
            return 1
        if (value === q)
            return 1000
        if (value.startsWith(q))
            return 800 - Math.min(200, value.length - q.length)

        const contained = value.indexOf(q)
        if (contained >= 0)
            return 600 - Math.min(200, contained * 8)

        let qi = 0
        let first = -1
        let previous = -2
        let consecutive = 0
        for (let i = 0; i < value.length && qi < q.length; ++i) {
            if (value[i] !== q[qi])
                continue
            if (first < 0)
                first = i
            if (i === previous + 1)
                consecutive += 1
            previous = i
            qi += 1
        }

        if (qi !== q.length)
            return 0
        return 300 + consecutive * 12 - first * 3 - (value.length - q.length)
    }

    function search(query) {
        if (!enabled)
            return []

        const q = query.trim().toLowerCase()
        const found = []

        for (let i = 0; i < applications.length; ++i) {
            const app = applications[i]
            if (!app || app.noDisplay)
                continue

            const nameScore = fuzzyScore(q, app.name)
            const genericScore = fuzzyScore(q, app.genericName) * 0.72
            const commentScore = fuzzyScore(q, app.comment) * 0.45
            const score = q.length === 0 ? 1 : Math.max(nameScore,
                genericScore, commentScore)

            if (score <= 0)
                continue

            found.push({
                id: app.id,
                providerId: providerId,
                kind: "desktop-app",
                title: app.name || app.id,
                subtitle: app.genericName || app.comment || app.id,
                icon: app.icon || "application-x-executable",
                score: score,
                app: app
            })
        }

        found.sort(function(a, b) {
            if (a.score !== b.score)
                return b.score - a.score
            return a.title.localeCompare(b.title)
        })

        return found.slice(0, 80)
    }

    function execute(result) {
        if (result?.app)
            result.app.execute()
    }
}
