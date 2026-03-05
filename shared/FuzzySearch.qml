pragma Singleton
import QtQuick

QtObject {
    id: root

    function score(pattern, target) {
        if (!pattern || pattern === "") {
            return 100
        }
        
        if (!target || target === "") {
            return 0
        }

        let p = pattern.toLowerCase()
        let t = target.toLowerCase()
        
        if (p === t) {
            return 100
        }
        
        if (t.startsWith(p)) {
            return 90 + (p.length / t.length) * 5
        }
        
        if (t.includes(p)) {
            return 80 + (p.length / t.length) * 5
        }
        
        let score = 0
        let pIndex = 0
        let tIndex = 0
        let consecutiveMatches = 0
        
        while (pIndex < p.length && tIndex < t.length) {
            if (p[pIndex] === t[tIndex]) {
                score += 10
                score += (consecutiveMatches * 5)
                
                if (tIndex === 0 || t[tIndex - 1] === " " || t[tIndex - 1] === "-" || t[tIndex - 1] === ".") {
                    score += 20
                }
                
                pIndex++
                consecutiveMatches++
            } else {
                consecutiveMatches = 0
            }
            tIndex++
        }
        
        if (pIndex === p.length) {
            let lengthPenalty = Math.max(0, (t.length - p.length) * 0.5)
            return Math.max(1, score - lengthPenalty)
        }
        
        return 0
    }

    function filter(pattern, items, keySelector) {
        if (!pattern || pattern === "") {
            return items
        }
        
        let scoredItems = []
        for (let i = 0; i < items.length; i++) {
            let item = items[i]
            let target = keySelector(item)
            let s = root.score(pattern, target)
            
            if (s > 0) {
                scoredItems.push({
                    "item": item,
                    "score": s
                })
            }
        }
        
        scoredItems.sort((a, b) => b.score - a.score)
        
        let result = []
        for (let i = 0; i < scoredItems.length; i++) {
            result.push(scoredItems[i].item)
        }
        
        return result
    }
}
