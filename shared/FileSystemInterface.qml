import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string currentPath: Quickshell.env("HOME")
    property bool isShowingHiddenFiles: false
    property bool containsImages: false
    
    readonly property alias fileModel: fileListModel
    ListModel { id: fileListModel }

    Process {
        id: listProcess
        command: ["ls", root.isShowingHiddenFiles ? "-1ap" : "-1p", root.currentPath]
        stdout: StdioCollector {
            onStreamFinished: {
                fileListModel.clear()
                let lines = text.trim().split("
")
                let imageCount = 0
                
                if (root.currentPath !== "/") {
                    fileListModel.append({ 
                        "name": "..", 
                        "path": "..", 
                        "isDir": true, 
                        "isImage": false 
                    })
                }
                
                let fileItems = []
                
                for (let line of lines) {
                    let trimmedLine = line.trim()
                    if (trimmedLine === "" || trimmedLine === "./" || trimmedLine === "../" || trimmedLine === ".") continue
                    
                    let isDirectory = trimmedLine.endsWith("/")
                    let fileName = isDirectory ? trimmedLine.slice(0, -1) : trimmedLine
                    let absolutePath = root.currentPath + (root.currentPath === "/" ? "" : "/") + fileName
                    
                    let isImageFile = !!fileName.match(/\.(jpg|jpeg|png|webp)$/i)
                    
                    if (isDirectory || isImageFile) {
                        fileItems.push({ 
                            "name": fileName, 
                            "path": absolutePath, 
                            "isDir": isDirectory, 
                            "isImage": isImageFile 
                        })
                        if (!isDirectory && isImageFile) imageCount++
                    }
                }
                
                root.containsImages = imageCount > 0
                
                fileItems.sort((a, b) => {
                    if (a.isDir !== b.isDir) return a.isDir ? -1 : 1
                    return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
                })
                
                for (let i = 0; i < fileItems.length; i++) {
                    fileListModel.append(fileItems[i])
                }
            }
        }
    }

    function refresh() {
        listProcess.running = false
        Qt.callLater(() => { listProcess.running = true })
    }

    function navigateToPath(path) {
        if (path === "..") {
            let pathSegments = root.currentPath.split("/")
            pathSegments.pop()
            root.currentPath = pathSegments.join("/") || "/"
        } else {
            if (path.startsWith("/")) {
                 root.currentPath = path
            } else {
                 root.currentPath = root.currentPath + (root.currentPath === "/" ? "" : "/") + path
            }
        }
        root.refresh()
    }
    
    function navigateToParent() {
        root.navigateToPath("..")
    }

    Component.onCompleted: {
        root.refresh()
    }

    onIsShowingHiddenFilesChanged: root.refresh()
    onCurrentPathChanged: root.refresh()
}
