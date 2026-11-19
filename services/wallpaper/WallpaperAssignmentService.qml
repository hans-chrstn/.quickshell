pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.wallpaper

Singleton {
    id: root

    property alias globalWallpaper: data.globalWallpaper
    property alias screenWallpapers: data.screenWallpapers
    property alias lockWallpaper: data.lockWallpaper
    property alias lockUsesDesktop: data.lockUsesDesktop
    property alias placements: data.placements
    property bool loaded: false
    property string error: ""
    readonly property bool automationOverridesLoaded: WallpaperAutomationOverrideService.loaded

    function normalizePath(path) {
        return String(path || "").trim();
    }

    function validWallpaper(path) {
        const normalized = normalizePath(path);
        if (normalized.length === 0 || WallpaperCatalogService.isExcluded(normalized))
            return false;
        const media = WallpaperProbeService.recordFor(normalized);
        if (media.state === "ready")
            return WallpaperRenderSupportService.supported(media);
        return WallpaperCatalogService.isSupported(normalized);
    }

    function wallpaperForScreen(screenName) {
        const name = String(screenName || "");
        const assigned = screenWallpapers[name];
        return assigned && String(assigned).length > 0 ? String(assigned) : globalWallpaper;
    }

    function wallpaperForLockScreen(screenName) {
        return lockUsesDesktop ? wallpaperForScreen(screenName) : lockWallpaper;
    }

    function setLock(path) {
        const normalized = normalizePath(path);
        if (!validWallpaper(normalized)) {
            error = "Unsupported wallpaper path";
            return false;
        }
        lockWallpaper = normalized;
        lockUsesDesktop = false;
        error = "";
        return true;
    }

    function useDesktopForLock() {
        lockUsesDesktop = true;
        error = "";
    }

    function assignTarget(target, screenName, path) {
        if (target === "lock")
            return setLock(path);
        return String(screenName || "").length > 0 ? setForScreen(screenName, path) : setGlobal(path);
    }

    function placementKey(target, screenName, path) {
        return JSON.stringify([target === "lock" ? "lock" : "desktop", String(screenName || ""), normalizePath(path)]);
    }

    function placementFor(target, screenName, path) {
        const fallback = {
            zoom: 1,
            panX: 0,
            panY: 0,
            rotation: 0
        };
        if (!path)
            return fallback;
        const specific = placements[placementKey(target, screenName, path)];
        if (specific)
            return specific;
        return target === "desktop" && String(screenName || "").length > 0 ? placements[placementKey(target, "", path)] || fallback : fallback;
    }

    function setPlacement(target, screenName, path, zoom, panX, panY, rotation) {
        const normalized = normalizePath(path);
        if (!validWallpaper(normalized) || !WallpaperCatalogService.isSupported(normalized)) {
            error = "Placement requires a supported static image";
            return false;
        }
        const scale = Number(zoom);
        const x = Number(panX);
        const y = Number(panY);
        const angle = Number(rotation);
        if (![scale, x, y, angle].every(Number.isFinite) || scale < 1 || scale > 3 || Math.abs(x) > 1 || Math.abs(y) > 1 || [0, 90, 180, 270].indexOf(angle) < 0) {
            error = "Wallpaper placement is out of range";
            return false;
        }
        const next = Object.assign({}, placements);
        const key = placementKey(target, screenName, normalized);
        if (!(key in next) && Object.keys(next).length >= 128)
            delete next[Object.keys(next)[0]];
        next[key] = {
            zoom: scale,
            panX: x,
            panY: y,
            rotation: angle
        };
        placements = next;
        error = "";
        return true;
    }

    function clearPlacement(target, screenName, path) {
        const key = placementKey(target, screenName, path);
        const next = Object.assign({}, placements);
        delete next[key];
        placements = next;
        error = "";
    }

    function setGlobal(path, suppressAutomation) {
        const manual = suppressAutomation !== false;
        if (manual && !automationOverridesLoaded) {
            error = "Wallpaper automation overrides are still loading";
            return false;
        }
        const normalized = normalizePath(path);
        if (!validWallpaper(normalized)) {
            error = "Unsupported wallpaper path";
            return false;
        }
        error = "";
        screenWallpapers = ({});
        globalWallpaper = normalized;
        if (manual)
            WallpaperAutomationOverrideService.suppressGlobal();
        return true;
    }

    function clearGlobal() {
        error = "";
        globalWallpaper = "";
    }

    function setForScreen(screenName, path, suppressAutomation) {
        const name = String(screenName || "").trim();
        const manual = suppressAutomation !== false;
        if (manual && !automationOverridesLoaded) {
            error = "Wallpaper automation overrides are still loading";
            return false;
        }
        const normalized = normalizePath(path);
        if (name.length === 0 || !validWallpaper(normalized)) {
            error = name.length === 0 ? "A screen name is required" : "Unsupported wallpaper path";
            return false;
        }

        const updated = ({});
        for (const key in screenWallpapers)
            updated[key] = screenWallpapers[key];
        updated[name] = normalized;
        error = "";
        screenWallpapers = updated;
        if (manual)
            WallpaperAutomationOverrideService.suppressScreen(name);
        return true;
    }

    function clearScreen(screenName) {
        const name = String(screenName || "").trim();
        if (name.length === 0)
            return;
        const updated = ({});
        for (const key in screenWallpapers) {
            if (key !== name)
                updated[key] = screenWallpapers[key];
        }
        error = "";
        screenWallpapers = updated;
    }

    function snapshot() {
        return {
            loaded: loaded,
            global: globalWallpaper,
            screens: Object.assign({}, screenWallpapers),
            lock: lockWallpaper,
            lockUsesDesktop: lockUsesDesktop,
            placementCount: Object.keys(placements).length,
            error: error
        };
    }

    Timer {
        id: saveTimer
        interval: 180
        onTriggered: stateFile.writeAdapter()
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("wallpaper-assignments.json")
        watchChanges: true
        printErrors: false
        onAdapterUpdated: if (root.loaded)
            saveTimer.restart()
        onFileChanged: reload()
        onLoaded: {
            root.loaded = true;
            root.error = "";
        }
        onLoadFailed: failure => {
            if (failure === FileViewError.FileNotFound) {
                root.loaded = true;
            } else {
                root.error = "Wallpaper assignments could not be loaded";
            }
        }

        JsonAdapter {
            id: data
            property string globalWallpaper: ""
            property var screenWallpapers: ({})
            property string lockWallpaper: ""
            property bool lockUsesDesktop: true
            property var placements: ({})
        }
    }
}
