import QtQuick
import Quickshell
import Quickshell.Io

Process {
    id: root
    
    property string binary: ""
    property bool exists: false
    property bool checkOnStart: true
    
    command: ["which", binary]
    
    onExited: (code) => {
        root.exists = (code === 0)
    }
    
    Component.onCompleted: {
        if (checkOnStart && binary !== "") running = true
    }
    
    onBinaryChanged: {
        if (checkOnStart) running = true
    }
}
