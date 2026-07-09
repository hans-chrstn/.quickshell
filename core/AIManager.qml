pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool isLoading: false

    property ListModel messages: ListModel { }

    readonly property string apiKey: "sk-f2f279d85f22469083e36dbea9a500a4"
    readonly property string apiUrl: "https://api.deepseek.com/chat/completions"
    readonly property string model: "deepseek-chat"

    function sendMessage(text) {
        if (root.isLoading || text.trim() === "") {
            return
        }

        root.isLoading = true
        messages.append({ "role": "user", "content": text })

        let apiMessages = []
        apiMessages.push({ "role": "system", "content": "You are a helpful assistant embedded in a desktop shell called Quickshell. Keep responses concise." })

        for (let i = 0; i < messages.count; i++) {
            let msg = messages.get(i)
            apiMessages.push({ "role": msg.role, "content": msg.content })
        }

        let xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.isLoading = false
                if (xhr.status === 200) {
                    try {
                        let data = JSON.parse(xhr.responseText)
                        let reply = data.choices[0].message.content
                        messages.append({ "role": "assistant", "content": reply })
                    } catch (e) {
                        messages.append({ "role": "assistant", "content": "Error parsing response." })
                    }
                } else {
                    let errorMsg = "API error (HTTP " + xhr.status + ")"
                    try {
                        let err = JSON.parse(xhr.responseText)
                        if (err.error && err.error.message) {
                            errorMsg = err.error.message
                        }
                    } catch (e) {}
                    messages.append({ "role": "assistant", "content": errorMsg })
                }
            }
        }
        xhr.open("POST", root.apiUrl)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.setRequestHeader("Authorization", "Bearer " + root.apiKey)
        xhr.send(JSON.stringify({
            model: root.model,
            messages: apiMessages
        }))
    }

    function clearChat() {
        messages.clear()
    }

    function regenerate() {
        if (messages.count < 2) {
            return
        }

        let lastUserIndex = -1
        for (let i = messages.count - 1; i >= 0; i--) {
            if (messages.get(i).role === "user") {
                lastUserIndex = i
                break
            }
        }

        if (lastUserIndex < 0) {
            return
        }

        messages.remove(lastUserIndex + 1, messages.count - lastUserIndex - 1)

        let lastUserMsg = messages.get(lastUserIndex).content
        messages.remove(lastUserIndex, 1)

        root.sendMessage(lastUserMsg)
    }
}
