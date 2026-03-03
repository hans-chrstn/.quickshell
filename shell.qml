//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma Env QT_MEDIA_BACKEND=ffmpeg
//@ pragma Env QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material

import QtQuick
import Quickshell
import qs.core
import qs.ui.screens
import qs.ui.shared

ShellRoot {
    id: root

    LazyContainer {
        active: true
        component: Lock { }
    }

    Loader {
        id: orchestratorLoader
        active: true
        sourceComponent: WindowOrchestrator { }
    }
}
