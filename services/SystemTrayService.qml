pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: root

    readonly property var model: SystemTray.items
    
    property var values: []

    Connections {
        target: SystemTray.items
        function onValuesChanged() {
            root.values = [...SystemTray.items.values]
        }
    }

    readonly property int count: (values && values.length) ? values.length : 0
    
    property int hoveredIndex: -1

    Component.onCompleted: {
        root.values = [...SystemTray.items.values]
    }
}
