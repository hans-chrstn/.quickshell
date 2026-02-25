pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: root

    readonly property var itemModel: SystemTray.items
    
    property var items: []

    Connections {
        target: SystemTray.items
        function onValuesChanged() {
            root.items = [...SystemTray.items.values]
        }
    }

    readonly property int itemCount: items ? items.length : 0
    
    property int hoveredIndex: -1

    Component.onCompleted: {
        root.items = [...SystemTray.items.values]
    }
}
