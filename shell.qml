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
import qs.ui.features.island.corners
import qs.ui.shared
import qs.core
import qs.ui.screens
import qs.ui.features.notifications

ShellRoot {
    id: root

    LazyContainer {
        active: true
        component: Lock { }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: topBarDelegate
            required property var modelData
            
            component: TopBar { 
                aboveWindows: true 
                screen: topBarDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: leftBarDelegate
            required property var modelData
            
            component: LeftBar { 
                aboveWindows: true 
                screen: leftBarDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: rightBarDelegate
            required property var modelData
            
            component: RightBar { 
                aboveWindows: true 
                screen: rightBarDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: bottomBarDelegate
            required property var modelData
            
            component: BottomBar { 
                aboveWindows: true 
                screen: bottomBarDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: topLeftDelegate
            required property var modelData
            
            component: CornerTopLeft {
                screen: topLeftDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: topRightDelegate
            required property var modelData
            
            component: CornerTopRight {
                screen: topRightDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: bottomLeftDelegate
            required property var modelData
            
            component: CornerBottomLeft {
                screen: bottomLeftDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: bottomRightDelegate
            required property var modelData
            
            component: CornerBottomRight {
                screen: bottomRightDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: notificationDelegate
            required property var modelData
            
            component: NotificationPopup { 
                modelData: notificationDelegate.modelData
            }
        }
    }
}
