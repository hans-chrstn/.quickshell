import QtQuick
import Quickshell.Hyprland

QtObject {
    property GlobalShortcut zenMode: GlobalShortcut {
        appid: "new-shell"
        name: "island-zen"
        description: "Toggle automatic Dynamic Island displays on the focused screen"
        onPressed: IslandPresentationService.toggleZen("")
    }
}
