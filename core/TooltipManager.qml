pragma Singleton
import QtQuick

QtObject {
    id: root

    property string text: ""
    property string description: ""
    property Item targetItem: null
    property bool active: false
    
    function show(item, text, description = "") {
        if (!item || !text || text === "") {
            return
        }
        
        root.targetItem = item
        root.text = text
        root.description = description
        root.active = true
    }

    function hide(item) {
        if (root.targetItem === item) {
            root.active = false
            root.targetItem = null
            root.text = ""
            root.description = ""
        }
    }
}
