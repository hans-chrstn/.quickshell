//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.bars
import qs.modules.island
import qs.components
import qs.config

ShellRoot {
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
}
