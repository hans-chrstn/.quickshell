pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property var constructionProfiles: ({
        modest: {
            label: "Modest desktop",
            controls: "200% CPU · 2 GiB maximum",
            launcherMs: 5,
            settingsMs: 3.7,
            wallpaperMs: 1.5
        },
        stress: {
            label: "Synthetic stress",
            controls: "25% CPU · 768 MiB maximum",
            launcherMs: 30,
            settingsMs: 35,
            settingsPeakMs: 51,
            wallpaperMs: 17.5,
            wallpaperPeakMs: 21,
            throttledPeriods: 1682,
            totalPeriods: 2190
        }
    })

    readonly property var staticBaseline: ({
        label: "Three-monitor static baseline",
        rssKiB: 274428,
        pssKiB: 209978,
        privateAnonymousKiB: 130640,
        measurement: "whole process after 31 seconds"
    })

    readonly property var attribution: ({
        structuralKiB: 27584,
        islandWindowsKiB: 71252,
        wallpaperWindowsKiB: 93356,
        fullShellKiB: 131844
    })

    readonly property string limitation:
        "Synthetic CPU and memory limits do not reproduce an integrated GPU, battery, or hardware decoder. RSS and sequential memory plateaus include allocator high-water behavior and do not equal live QML ownership."

    function snapshot() {
        return {
            capturedFrom: "accepted lifecycle measurement runs",
            observed: true,
            liveSampling: false,
            constructionProfiles: constructionProfiles,
            staticBaseline: staticBaseline,
            attribution: attribution,
            limitation: limitation
        }
    }
}
