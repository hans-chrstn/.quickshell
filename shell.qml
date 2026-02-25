//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma Env QT_MEDIA_BACKEND=ffmpeg
//@ pragma Env QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.bars
import qs.modules.island
import qs.components
import qs.services
import qs.modules.windows
import qs.modules.notifications

ShellRoot {
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
