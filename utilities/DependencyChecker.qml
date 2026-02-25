import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    property string binaryName: ""
    property string dbusBusName: ""
    property bool isAvailable: false
    property bool checkOnCreation: true
    
    signal availabilityChecked(bool available)

    function runCheck() {
        if (binaryName !== "") {
            binaryCheckProcess.running = true
        } else if (dbusBusName !== "") {
            dbusCheckProcess.running = true
        }
    }

    Process {
        id: binaryCheckProcess
        command: ["which", root.binaryName]
        onExited: (exitCode) => {
            root.isAvailable = (exitCode === 0)
            root.availabilityChecked(root.isAvailable)
        }
    }

    Process {
        id: dbusCheckProcess
        command: ["dbus-send", "--system", "--dest=org.freedesktop.DBus", "--type=method_call", "--print-reply", "/org/freedesktop/DBus", "org.freedesktop.DBus.ListNames"]
        onExited: (exitCode) => {
            if (exitCode === 0 && stdout) {
                root.isAvailable = stdout.readAll().includes(root.dbusBusName)
                root.availabilityChecked(root.isAvailable)
            }
        }
    }

    Component.onCompleted: {
        if (checkOnCreation) {
            runCheck()
        }
    }
}
