import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
  property var modelData
  screen: modelData
  anchors {
    left: true
    top: true
    bottom: true
  }
  focusable: true
  exclusionMode: ExclusionMode.Normal
  implicitWidth: 25
}
