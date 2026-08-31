pragma Singleton

import QtQuick
import Quickshell
import "WallpaperRenderSupport.js" as Support

Singleton {
    function rendererFor(media) {
        return Support.rendererFor(media)
    }

    function animatedBackendFor(media) {
        return Support.animatedBackendFor(media)
    }

    function supported(media) {
        return Support.supported(media)
    }
}
