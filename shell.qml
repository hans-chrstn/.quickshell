//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import Quickshell
import qs.modules.bars
import "components"

ShellRoot {
    Variants { model: Quickshell.screens; delegate: TopBar {} }
    Variants { model: Quickshell.screens; delegate: BottomBar {} }
    Variants { model: Quickshell.screens; delegate: LeftBar {} } 
    Variants { model: Quickshell.screens; delegate: RightBar {} }
    
    Variants { 
        model: Quickshell.screens
        delegate: ScreenCorner { activeTop: true; activeLeft: true }
    }
    Variants { 
        model: Quickshell.screens
        delegate: ScreenCorner { activeTop: true; activeRight: true }
    }
    Variants { 
        model: Quickshell.screens
        delegate: ScreenCorner { activeBottom: true; activeLeft: true }
    }
    Variants { 
        model: Quickshell.screens
        delegate: ScreenCorner { activeBottom: true; activeRight: true }
    }
}
