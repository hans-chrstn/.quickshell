import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

Item {
    id: root

    property string currentPath: Quickshell.env("HOME")
    property bool showHidden: false
    property bool hasImages: false
    
    readonly property alias model: fileListModel
    ListModel { id: fileListModel }

    Process {
        id: listProc
        command: ["ls", root.showHidden ? "-1ap" : "-1p", root.currentPath]
        stdout: StdioCollector {
            onStreamFinished: {
                fileListModel.clear()
                let lines = text.trim().split("\n")
                let imgCount = 0
                
                if (root.currentPath !== "/") {
                    fileListModel.append({ "name": "..", "path": "..", "isDir": true, "isImage": false })
                }
                
                let items = []
                
                for (let line of lines) {
                    let trimmed = line.trim()
                    if (trimmed === "" || trimmed === "./" || trimmed === "../" || trimmed === ".") continue
                    
                    let isDir = trimmed.endsWith("/")
                    let name = isDir ? trimmed.slice(0, -1) : trimmed
                    let path = root.currentPath + (root.currentPath === "/" ? "" : "/") + name
                    
                    let isImg = !!name.match(/\.(jpg|jpeg|png|webp)$/i)
                    
                    if (isDir || isImg) {
                        items.push({ "name": name, "path": path, "isDir": isDir, "isImage": isImg })
                        if (!isDir && isImg) imgCount++
                    }
                }
                
                root.hasImages = imgCount > 0
                
                items.sort((a, b) => {
                    if (a.isDir !== b.isDir) return a.isDir ? -1 : 1
                    return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
                })
                
                for (let i = 0; i < items.length; i++) {
                    fileListModel.append(items[i])
                }
            }
        }
    }

    function refresh(): void {
        listProc.running = false
        Qt.callLater(() => { listProc.running = true })
    }

    function changeDirectory(path: string): void {
        if (path === "..") {
            let parts = root.currentPath.split("/")
            parts.pop()
            root.currentPath = parts.join("/") || "/"
        } else {
            if (path.startsWith("/")) {
                 root.currentPath = path
            } else {
                 root.currentPath = root.currentPath + (root.currentPath === "/" ? "" : "/") + path
            }
        }
        root.refresh()
    }
    
    function goUp(): void {
        root.changeDirectory("..")
    }

    Component.onCompleted: {
        root.refresh()
    }

    onShowHiddenChanged: root.refresh()
    onCurrentPathChanged: root.refresh()
}
