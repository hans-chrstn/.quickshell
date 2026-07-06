pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Item {
  property bool isGestureActive: false
  Socket {
    path: "/tmp/crab.sock"
    connected: true

    parser: SplitParser {
      onRead: (data) => {
        let payload = JSON.parse(data);
        if (payload.action == "gesture") {
          isGestureActive = payload.event.value;
        }
      }
    }

  }
}
