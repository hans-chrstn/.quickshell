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
import Quickshell.Io
import qs.ui.panels
import qs.ui.features.island
import qs.ui.shared
import qs.core
import qs.ui.screens
import qs.ui.features.notifications

ShellRoot {
    id: root

    Lock { }

    Variants {
        model: Quickshell.screens
        delegate: TopBar { aboveWindows: true }
    }

    Variants {
        model: Quickshell.screens
        delegate: LeftBar { aboveWindows: true }
    }

    Variants {
        model: Quickshell.screens
        delegate: RightBar { aboveWindows: true }
    }

    Variants {
        model: Quickshell.screens
        delegate: BottomBar { aboveWindows: true }
    }

    Variants {
        model: Quickshell.screens
        delegate: CornerTopLeft { }
    }

    Variants {
        model: Quickshell.screens
        delegate: CornerTopRight { }
    }

    Variants {
        model: Quickshell.screens
        delegate: CornerBottomLeft { }
    }

    Variants {
        model: Quickshell.screens
        delegate: CornerBottomRight { }
    }

    Variants {
        model: Quickshell.screens
        delegate: NotificationPopup { }
    }
}
