import QtQuick
import Quickshell
import qs.core

Item {
    id: root
    
    property bool active: true
    property Component component: null
    readonly property alias item: loader.item
    readonly property bool loading: loader.loading
    
    LazyLoader {
        id: loader
        activeAsync: root.active
        component: root.component
        
        onItemChanged: {
            if (item && item.hasOwnProperty("parent")) {
                item.parent = root
                if (item.hasOwnProperty("anchors")) {
                    item.anchors.fill = root
                }
            }
        }
    }
}
