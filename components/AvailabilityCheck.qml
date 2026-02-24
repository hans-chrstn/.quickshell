import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    property string binary: ""
    property string dbusService: ""
    property bool exists: false
    property bool checkOnStart: true
    
    signal checked(bool exists)

    function refresh() {
        if (binary !== "") {
            binCheck.running = true
        } else if (dbusService !== "") {
            dbusCheck.running = true
        }
    }

    Process {
        id: binCheck
        command: ["which", root.binary]
        onExited: (code) => {
            root.exists = (code === 0)
            root.checked(root.exists)
        }
    }

    Process {
        id: dbusCheck
        command: ["dbus-send", "--system", "--dest=org.freedesktop.DBus", "--type=method_call", "--print-reply", "/org/freedesktop/DBus", "org.freedesktop.DBus.ListNames"]
        onExited: (code) => {
            if (code === 0 && stdout) {
                root.exists = stdout.readAll().includes(root.dbusService)
                root.checked(root.exists)
            }
        }
    }

    Component.onCompleted: {
        if (checkOnStart) refresh()
    }
}
