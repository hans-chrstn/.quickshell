pragma Singleton

import QtQuick
import Quickshell
import qs.core

Singleton {
    id: root

    property bool active: false
    property string activeScreenName: ""
    property point startPoint: Qt.point(0, 0)
    property rect selection: Qt.rect(0, 0, 0, 0)
    
    signal areaSelected(rect area)
    signal canceled()

    function start() {
        root.selection = Qt.rect(0, 0, 0, 0)
        root.active = true
    }

    function update(currentPoint) {
        let x = Math.min(root.startPoint.x, currentPoint.x)
        let y = Math.min(root.startPoint.y, currentPoint.y)
        let w = Math.abs(root.startPoint.x - currentPoint.x)
        let h = Math.abs(root.startPoint.y - currentPoint.y)
        
        root.selection = Qt.rect(x, y, w, h)
    }

    function finish() {
        if (root.selection.width > 10 && root.selection.height > 10) {
            root.areaSelected(root.selection)
        } else {
            root.canceled()
        }
        root.active = false
    }

    function selectWholeScreen(width, height) {
        root.selection = Qt.rect(0, 0, width, height)
        root.finish()
    }

    function cancel() {
        root.active = false
        root.canceled()
    }
}
