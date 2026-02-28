import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.core
import qs.ui.shared

Item {
    id: root

    property alias currentIndex: view.currentIndex
    property alias count: tabModel.count
    property alias moving: view.moving
    property var activePlayer: null
    
    property alias tabModelRef: tabModel

    Connections {
        target: SystemTrayManager
        function onHoveredIndexChanged() {
            if (SystemTrayManager.hoveredIndex !== -1) {
                for (let i = 0; i < tabModel.count; i++) {
                    if (tabModel.get(i).type === "tray") {
                        view.currentIndex = i
                        break
                    }
                }
            }
        }
    }

    PathView {
        id: view
        anchors.fill: parent
        anchors.topMargin: 5
        anchors.bottomMargin: 20
        clip: true
        
        model: tabModel
        pathItemCount: Math.max(tabModel.count, 3)
        snapMode: PathView.SnapOneItem
        highlightRangeMode: PathView.StrictlyEnforceRange
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        dragMargin: width / 2
        
        path: Path {
            startX: -view.width * 2; startY: view.height / 2
            PathAttribute { name: "itemOpacity"; value: 0.0 }
            PathAttribute { name: "itemScale"; value: 0.6 }
            
            PathLine { x: -view.width * 0.5; y: view.height / 2 }
            PathPercent { value: 0.48 }
            PathAttribute { name: "itemOpacity"; value: 0.0 }
            PathAttribute { name: "itemScale"; value: 0.8 }
            
            PathLine { x: view.width * 0.5; y: view.height / 2 }
            PathPercent { value: 0.5 }
            PathAttribute { name: "itemOpacity"; value: 1.0 }
            PathAttribute { name: "itemScale"; value: 1.0 }
            
            PathLine { x: view.width * 1.5; y: view.height / 2 }
            PathPercent { value: 0.52 }
            PathAttribute { name: "itemOpacity"; value: 0.0 }
            PathAttribute { name: "itemScale"; value: 0.8 }
            
            PathLine { x: view.width * 3; y: view.height / 2 }
            PathPercent { value: 1.0 }
            PathAttribute { name: "itemOpacity"; value: 0.0 }
            PathAttribute { name: "itemScale"; value: 0.6 }
        }

        delegate: Item {
            id: delegateRoot
            width: view.width; height: view.height
            opacity: PathView.itemOpacity
            scale: PathView.itemScale
            enabled: PathView.isCurrentItem

            Item {
                id: tabContainer
                anchors.fill: parent
                anchors.leftMargin: 20; anchors.rightMargin: 20
                clip: true

                LazyLoader {
                    id: tabLoader
                    
                    activeAsync: true
                    
                    property var tabComponent: {
                        if (!model) return null;
                        if (model.type === "timeDate") return timeDateComp
                        if (model.type === "music") return musicComp
                        if (model.type === "weather") return weatherComp
                        if (model.type === "battery") return batteryComp
                        if (model.type === "notif") return notifComp
                        if (model.type === "cc") return ccComp
                        if (model.type === "tray") return trayComp
                        return null
                    }
                    
                    component: tabComponent

                    onItemChanged: {
                        if (item) {
                            item.parent = tabContainer
                            item.anchors.fill = tabContainer
                        }
                    }
                }
            }
        }
    }

    Component { id: timeDateComp; ClockDateDisplay { } }
    Component { id: musicComp; MediaPlaybackView { mediaPlayer: root.activePlayer } }
    Component { id: weatherComp; WeatherDisplay { } }
    Component { id: batteryComp; PowerStatusView {} }
    Component { id: notifComp; NotificationTab { } } 
    Component { id: ccComp; SystemDashboard { } }
    Component { id: trayComp; SystemTrayTab { } }

    ListModel {
        id: tabModel
        function updateModel() {
            clear();
            append({ "type": "timeDate" })
            append({ "type": "music" })
            append({ "type": "notif" })
            if (BatteryManager.isUPowerAvailable && BatteryManager.mainDevice && BatteryManager.mainDevice.type !== 0) append({ "type": "battery" })
            if (ThemeManager.isWeatherVisible) append({ "type": "weather" })
            append({ "type": "cc" })
            append({ "type": "tray" })
        }
        Component.onCompleted: updateModel()
    }
    
    Connections {
        target: ThemeManager
        function onIsWeatherVisibleChanged() { tabModel.updateModel() }
    }
    
    Connections {
        target: BatteryManager
        function onIsUPowerAvailableChanged() { tabModel.updateModel() }
    }
}
