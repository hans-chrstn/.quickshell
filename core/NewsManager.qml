pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: root

    property string activeSource: "wire"
    property bool isFetching: false
    
    readonly property ListModel newsStore: ListModel {
    }

    readonly property var sources: {
        return {
            "wire": "https://www.theguardian.com/world/rss",
            "global": "https://globalvoices.org/feed/"
        }
    }

    function fetchNews(manual = false) {
        if (root.isFetching) {
            return
        }
        
        let url = root.sources[root.activeSource]
        if (!url) {
            return
        }
        
        root.isFetching = true
        let xhr = new XMLHttpRequest()
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    root.parseRSS(xhr.responseText)
                } else {
                    console.error("NewsManager: Fetch failed with status", xhr.status)
                }
                root.isFetching = false
            }
        }
        
        xhr.onerror = function() {
            console.error("NewsManager: Network error during fetch")
            root.isFetching = false
        }
        
        xhr.open("GET", url)
        xhr.send()
    }

    function parseRSS(xml) {
        root.newsStore.clear()
        
        let itemRegex = /<item[\s\S]*?>([\s\S]*?)<\/item>/g
        let match
        let count = 0
        
        while ((match = itemRegex.exec(xml)) !== null && count < 25) {
            let itemContent = match[1]
            
            let title = root.extractTag(itemContent, "title")
            let link = root.extractTag(itemContent, "link")
            let desc = root.extractTag(itemContent, "description")
            let pubDate = root.extractTag(itemContent, "pubDate")
            
            title = root.cleanText(title)
            desc = root.cleanText(desc)
            
            if (title !== "") {
                root.newsStore.append({
                    "title": title,
                    "link": link.trim(),
                    "description": desc,
                    "date": pubDate.trim()
                })
                count++
            }
        }
    }

    function extractTag(xml, tag) {
        let regex = new RegExp("<" + tag + "[\\s\\S]*?>([\\s\\S]*?)<\\/" + tag + ">")
        let match = xml.match(regex)
        return match ? match[1] : ""
    }

    function cleanText(text) {
        let cleaned = text.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
        cleaned = cleaned.replace(/<[^>]*>/g, "")
        
        let entities = {
            "&quot;": "\"",
            "&amp;": "&",
            "&apos;": "'",
            "&lt;": "<",
            "&gt;": ">",
            "&nbsp;": " ",
            "&copy;": "©",
            "&reg;": "®",
            "&ndash;": "-",
            "&mdash;": "—",
            "&lsquo;": "'",
            "&rsquo;": "'",
            "&ldquo;": "\"",
            "&rdquo;": "\"",
            "&#039;": "'",
            "&#39;": "'"
        }
        
        for (let key in entities) {
            let r = new RegExp(key, "g")
            cleaned = cleaned.replace(r, entities[key])
        }
        
        return cleaned.trim()
    }

    onActiveSourceChanged: {
        root.fetchNews()
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.fetchNews()
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            root.fetchNews()
        })
    }
}
