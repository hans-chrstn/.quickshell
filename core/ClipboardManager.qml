pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: root

    property var history: []
    readonly property string cachePath: Quickshell.cachePath("clipboard_history.json")
    readonly property int maxItems: 30

    signal historyCleared()

    function add(text) {
        if (!text || text.trim() === "") return
        
        let newHistory = [...root.history]
        let idx = newHistory.indexOf(text)
        if (idx !== -1) newHistory.splice(idx, 1)
        
        newHistory.unshift(text)
        root.history = newHistory.slice(0, root.maxItems)
        
        save()
    }

    function save() {
        historyFile.setText(JSON.stringify(root.history))
    }

    function clear() {
        root.history = []
        Quickshell.clipboardText = ""
        root.historyCleared()
        
        Qt.callLater(() => {
            historyFile.setText("[]")
        })
    }

    function copyToClipboard(text) {
        if (!text) return
        Quickshell.clipboardText = text
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            let text = Quickshell.clipboardText
            if (text && text.trim() !== "" && (root.history.length === 0 || text !== root.history[0])) {
                root.add(text.trim())
            }
        }
    }

    FileView {
        id: historyFile
        path: root.cachePath
        onLoaded: {
            try {
                let content = text()
                if (content && content.trim() !== "") {
                    let data = JSON.parse(content)
                    if (Array.isArray(data)) root.history = data
                }
            } catch (e) {}
        }
    }
}
