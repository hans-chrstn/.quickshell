pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Item {
  property bool isGestureActive: false
  property bool hardwareGesturePressed: false
  property real gestureDeltaX: 0
  property real gestureDeltaY: 0
  property string socketPath: ""
  
  Timer {
      interval: 2000
      running: !crabSocket.connected
      repeat: true
      onTriggered: {
          pathCheckProcess.running = true;
      }
  }

  Process {
      id: pathCheckProcess
      command: ["sh", "-c", "if nc -U -z /run/crab/api.sock 2>/dev/null; then echo '/run/crab/api.sock'; elif nc -U -z /tmp/crab.sock 2>/dev/null; then echo '/tmp/crab.sock'; fi"]
      stdout: SplitParser {
          onRead: (data) => {
              let res = data.trim();
              if (res !== "" && socketPath !== res) {
                  socketPath = res;
              }
          }
      }
  }

  Socket {
    id: crabSocket
    path: socketPath
    connected: true

    parser: SplitParser {
      onRead: (data) => {
        try {
          let payload = JSON.parse(data);
          if (payload.action == "gesture") {
            let isPressed = (payload.event.value === true);
            if (isPressed && !hardwareGesturePressed) {
                isGestureActive = !isGestureActive;
                gestureDeltaX = 0;
                gestureDeltaY = 0;
            }
            hardwareGesturePressed = isPressed;
          } else if (payload.action == "horizontal_scroll") {
            gestureDeltaX += payload.event.value * 2; 
          } else if (payload.action == "Vertical_scroll") {
            gestureDeltaY += payload.event.value * 2;
          } else if (payload.action == "forward") {
            if (payload.event.value === true && ThemeManager.mouseForwardCommand) {
                Quickshell.execDetached(["sh", "-c", ThemeManager.mouseForwardCommand]);
            }
          } else if (payload.action == "back") {
            if (payload.event.value === true && ThemeManager.mouseBackCommand) {
                Quickshell.execDetached(["sh", "-c", ThemeManager.mouseBackCommand]);
            }
          } else if (payload.action == "action") {
            if (payload.event.value === true && ThemeManager.mouseActionCommand) {
                Quickshell.execDetached(["sh", "-c", ThemeManager.mouseActionCommand]);
            }
          } else if (payload.action == "middle_click") {
            if (payload.event.value === true && ThemeManager.mouseMiddleCommand) {
                Quickshell.execDetached(["sh", "-c", ThemeManager.mouseMiddleCommand]);
            }
          } else if (payload.action == "center") {
            if (payload.event.value === true && ThemeManager.mouseCenterCommand) {
                Quickshell.execDetached(["sh", "-c", ThemeManager.mouseCenterCommand]);
            }
          }
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: 3000
    running: !crabSocket.connected
    repeat: true
    onTriggered: {
      crabSocket.connected = true;
    }
  }
}
