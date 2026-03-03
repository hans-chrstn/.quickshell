import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.shared

Column {
    id: root
    
    spacing: 6
    
    property var screen: null
    readonly property string screenIdentifier: screen ? screen.name : ""
    
    Process {
        id: recorder
        
        function startRecording(geometry) {
            let home = Quickshell.env("HOME") || "/tmp"
            let timestamp = new Date().getTime()
            let filename = home + "/Videos/recording_" + root.screenIdentifier + "_" + timestamp + ".mp4"
            
            let args = ["wf-recorder", "-a", "-f", filename]
            
            if (geometry && geometry !== "") {
                args.push("-g")
                args.push(geometry)
            } else {
                args.push("-o")
                args.push(root.screenIdentifier)
            }
            
            command = args
            running = true
            
            Quickshell.execDetached(["notify-send", "Recording Started", "Mode: " + (geometry ? "Region" : "Fullscreen") + "\nFile: " + filename])
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && exitCode !== 130) {
                Quickshell.execDetached(["notify-send", "Recorder Stopped", "Error code: " + exitCode])
            } else {
                Quickshell.execDetached(["notify-send", "Recording Saved", "File saved to Videos/"])
            }
        }
    }

    Connections {
        target: AreaPickerManager
        function onAreaSelected(area) {
            if (AreaPickerManager.activeScreenName !== root.screenIdentifier) return
            
            let globalX = Math.round(area.x + (root.screen ? root.screen.x : 0))
            let globalY = Math.round(area.y + (root.screen ? root.screen.y : 0))
            let geo = globalX + "," + globalY + " " + Math.round(area.width) + "x" + Math.round(area.height)
            
            recorder.startRecording(geo)
        }
    }

    BaseButton {
        id: recBtn
        anchors.horizontalCenter: parent.horizontalCenter
        width: 44
        height: 44
        cornerRadius: 22
        
        onClicked: {
            if (!recorder.running) {
                AreaPickerManager.activeScreenName = root.screenIdentifier
                AreaPickerManager.start()
            } else {
                recorder.running = false
            }
        }
        
        Rectangle {
            anchors.fill: parent
            radius: 22
            color: recorder.running ? ThemeManager.dangerColor : "white"
            opacity: recorder.running ? 1.0 : (recBtn.isHovered ? 0.3 : 0.1)
            
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on color { ColorAnimation { duration: 200 } }
            
            Rectangle {
                anchors.centerIn: parent
                width: recorder.running ? 14 : 18
                height: width
                radius: recorder.running ? 3 : 9
                color: "white"
                
                Behavior on width { NumberAnimation { duration: 200 } }
                Behavior on radius { NumberAnimation { duration: 200 } }
            }
        }
    }
    
    StyledLabel {
        anchors.horizontalCenter: parent.horizontalCenter
        text: recorder.running ? "STOP" : "REC"
        type: "caption"
        customColor: recorder.running ? ThemeManager.dangerColor : "white"
        opacity: (recBtn.isHovered || recorder.running) ? 1.0 : 0.6
        font.weight: Font.Black
        font.letterSpacing: 1
        
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
