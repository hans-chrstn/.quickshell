pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQml.Models
import Niri 0.1

Singleton {
    id: root

    property bool isNiri: Quickshell.env("NIRI_SOCKET") !== undefined && Quickshell.env("NIRI_SOCKET") !== null && Quickshell.env("NIRI_SOCKET") !== ""

    property var workspaces: isNiri ? niri.workspaces : Hyprland.workspaces
    property var windows: isNiri ? niri.windows : ToplevelManager.toplevels
    property var focusedWindow: isNiri ? niri.focusedWindow : ToplevelManager.activeToplevel
    readonly property bool isConnected: isNiri ? niri.isConnected() : true

    property var windowLayouts: ({})
    signal layoutsChanged()

    Niri {
        id: niri
        Component.onCompleted: {
            if (isNiri) connect()
        }
        onErrorOccurred: (err) => console.error("[WindowManager] Error:", err)
    }

    function forceUpdateLayouts() {
        if (refreshProcess.running) return
        refreshProcess.running = true
    }

    Process {
        id: refreshProcess
        command: isNiri ? ["niri", "msg", "-j", "windows"] : ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let windows = JSON.parse(text)
                    let nextLayouts = {}
                    if (isNiri) {
                        for (let i = 0; i < windows.length; i++) {
                            let win = windows[i]
                            nextLayouts[win.id] = win.layout
                        }
                    } else {
                        for (let i = 0; i < windows.length; i++) {
                            let win = windows[i]
                            let hexAddr = win.address.replace("0x", "")
                            nextLayouts[hexAddr] = win
                        }
                    }
                    root.windowLayouts = nextLayouts
                    root.layoutsChanged()
                } catch(e) {}
            }
        }
    }

    function getWindowLayout(id) {
        return root.windowLayouts[id] || null
    }

    function focusWorkspaceById(id) {
        if (isNiri) {
            niri.focusWorkspaceById(id)
        } else {
            if (Hyprland && Hyprland.workspaces) {
                for (let i = 0; i < Hyprland.workspaces.count; i++) {
                    let ws = Hyprland.workspaces.get(i)
                    if (ws.id === id || ws.name === id.toString()) {
                        ws.activate()
                        break
                    }
                }
            }
        }
    }

    function focusWindowById(id) {
        if (!id) return;
        if (isNiri) {
            niri.focusWindow(id)
        } else {
            if (typeof id === "string") {
                Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:0x" + id])
            } else if (id.activate) {
                id.activate()
            }
        }
    }

    function moveWindowToWorkspace(windowId, workspaceRef) {
        if (windowId === undefined || workspaceRef === null) return
        
        if (isNiri) {
            Quickshell.execDetached([
                "sh", "-c", 
                "niri msg action move-window-to-workspace " + workspaceRef + " --window-id " + windowId + 
                " && niri msg action focus-workspace " + workspaceRef
            ])
        } else {
            if (typeof windowId === "string") {
                Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspace", workspaceRef + ",address:0x" + windowId])
            } else {
                Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspace", workspaceRef.toString()])
            }
        }

        OSDManager.show(
            "Moved to Workspace " + workspaceRef,
            ThemeManager.iconWindow
        )
    }

    function closeWindowById(id) {
        if (!id) return;
        if (isNiri) niri.closeWindow(id)
        else if (id.close) id.close()
    }

    property var runningApplications: ({})

    Instantiator {
        model: root.windows
        delegate: QtObject {
            readonly property string normalizedAppId: model.appId ? model.appId.toLowerCase() : ""
            readonly property var windowId: root.isNiri ? model.id : model
            
            Component.onCompleted: {
                if (normalizedAppId) {
                    if (!root.runningApplications[normalizedAppId]) {
                        root.runningApplications[normalizedAppId] = []
                    }
                    root.runningApplications[normalizedAppId].push(windowId)
                    root.runningApplicationsChanged()
                }
            }
            Component.onDestruction: {
                if (normalizedAppId && root.runningApplications[normalizedAppId]) {
                    let arr = root.runningApplications[normalizedAppId]
                    let index = arr.indexOf(windowId)
                    if (index !== -1) {
                        arr.splice(index, 1)
                        if (arr.length === 0) {
                            delete root.runningApplications[normalizedAppId]
                        }
                        root.runningApplicationsChanged()
                    }
                }
            }
        }
    }

    function isApplicationRunning(desktopAppId) {
        if (!desktopAppId) return false
        let searchId = desktopAppId.toString().replace(".desktop", "").toLowerCase()
        if (root.runningApplications[searchId]) return true
        for (let key in root.runningApplications) {
            if (key.includes(searchId) || searchId.includes(key)) return true
        }
        return false
    }

    function focusApplication(desktopAppId) {
        if (!desktopAppId) return false
        let searchId = desktopAppId.toString().replace(".desktop", "").toLowerCase()
        let appWindows = getApplicationWindows(desktopAppId)
        if (appWindows.length === 0) return false
        if (appWindows.length === 1) {
            focusWindowById(appWindows[0].id)
            return true
        }
        let currentFocusedId = focusedWindow ? focusedWindow.id : -1
        let currentIndex = -1
        for (let i = 0; i < appWindows.length; i++) {
            if (appWindows[i].id === currentFocusedId) {
                currentIndex = i
                break
            }
        }
        if (currentIndex !== -1) {
            let nextIndex = (currentIndex + 1) % appWindows.length
            focusWindowById(appWindows[nextIndex].id)
        } else {
            focusWindowById(appWindows[appWindows.length - 1].id)
        }
        return true
    }

    function getApplicationWindows(desktopAppId) {
        if (!desktopAppId) return []
        let searchId = desktopAppId.toString().replace(".desktop", "").toLowerCase()
        let windows = []
        for (let i = 0; i < root.windows.count; i++) {
            if (isNiri) {
                let index = root.windows.index(i, 0)
                let appId = root.windows.data(index, 259)
                if (appId && appId.toLowerCase().includes(searchId)) {
                    let id = root.windows.data(index, 257)
                    let title = root.windows.data(index, 258)
                    windows.push({ id: id, title: title })
                }
            } else {
                let win = root.windows.get(i)
                if (win.appId && win.appId.toLowerCase().includes(searchId)) {
                    windows.push({ id: win, title: win.title })
                }
            }
        }
        return windows
    }

    function getAllWindows() {
        let list = []
        for (let i = 0; i < root.windows.count; i++) {
            if (isNiri) {
                let index = root.windows.index(i, 0)
                let appId = root.windows.data(index, 259) || ""
                let title = root.windows.data(index, 258) || ""
                let winId = root.windows.data(index, 257)
                list.push({ id: winId, title: title, appId: appId })
            } else {
                let win = root.windows.get(i)
                list.push({ id: win, title: win.title || "", appId: win.appId || "" })
            }
        }
        return list
    }

    function getWorkspaceWindows(wsId) {
        let list = []
        if (isNiri) {
            let layouts = root.windowLayouts
            for (let i = 0; i < root.windows.count; i++) {
                let idx = root.windows.index(i, 0)
                let wId = root.windows.data(idx, 261)
                
                if (wId === wsId) {
                    let id = root.windows.data(idx, 257)
                    let pid = root.windows.data(idx, 260)
                    let appId = root.windows.data(idx, 259) || ""
                    let title = root.windows.data(idx, 258) || ""
                    let iconPath = root.windows.data(idx, 265) || ""
                    let isFocused = root.windows.data(idx, 262) || false
                    let isUrgent = root.windows.data(idx, 264) || false
                    
                    let layout = layouts[id]
                    let w = 100, h = 100, posX = 0
                    if (layout) {
                        w = layout.window_size ? layout.window_size[0] : (layout.tile_size ? layout.tile_size[0] : 100)
                        h = layout.window_size ? layout.window_size[1] : (layout.tile_size ? layout.tile_size[1] : 100)
                        posX = layout.pos_in_scrolling_layout ? layout.pos_in_scrolling_layout[0] : 0
                    }
                    
                    list.push({
                        id: id,
                        pid: pid,
                        appId: appId,
                        title: title,
                        iconPath: iconPath,
                        isFocused: isFocused,
                        isUrgent: isUrgent,
                        width: w,
                        height: h,
                        posX: posX
                    })
                }
            }
        } else {
            let layouts = root.windowLayouts;
            for (let addr in layouts) {
                let win = layouts[addr]
                if (win.workspace && win.workspace.id === wsId) {
                    list.push({
                        id: addr,
                        pid: win.pid || 0,
                        appId: win.class || "",
                        title: win.title || "",
                        iconPath: "",
                        isFocused: (Hyprland.activeToplevel && Hyprland.activeToplevel.address === addr),
                        isUrgent: false,
                        width: win.size ? win.size[0] : 100,
                        height: win.size ? win.size[1] : 100,
                        posX: win.at ? win.at[0] : 0,
                        posY: win.at ? win.at[1] : 0
                    })
                }
            }
        }
        return list
    }

    function getWorkspaceProps(model) {
        if (!model) return null;
        if (isNiri) {
            return {
                id: model.id,
                name: model.name,
                isActive: model.isActive,
                isFocused: model.isFocused,
                output: model.output
            }
        } else {
            return {
                id: model.id,
                name: model.name,
                isActive: model.active,
                isFocused: model.focused,
                output: model.monitor ? model.monitor.name : ""
            }
        }
    }
}
