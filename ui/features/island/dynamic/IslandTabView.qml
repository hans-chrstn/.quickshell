import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.core
import qs.ui.shared
import qs.ui.features.island
import qs.ui.features.island.music
import qs.ui.features.island.clock
import qs.ui.features.island.weather
import qs.ui.features.island.system
import qs.ui.features.island.notifications
import qs.ui.features.island.tray

Item {
    id: root

    property var logic
    property alias currentIndex: view.currentIndex
    property alias offset: view.offset
    property alias moving: view.moving
    property alias count: view.count
    
    readonly property bool isSelectorExpanded: {
        if (view.currentItem) {
            let loader = view.currentItem.tabLoaderRef
            if (loader && loader.item && loader.item.isSelectorExpanded !== undefined) {
                return loader.item.isSelectorExpanded
            }
        }
        return false
    }

    function collapseSelectors() {
        if (view.currentItem) {
            let loader = view.currentItem.tabLoaderRef
            if (loader && loader.item && loader.item.collapseSelector !== undefined) {
                loader.item.collapseSelector()
            }
        }
    }

    PathView {
        id: view
        anchors.fill: parent
        anchors.topMargin: 5
        anchors.bottomMargin: 20
        clip: true

        model: logic ? logic.model : null
        pathItemCount: logic ? Math.max(logic.model.count, 3) : 0
        snapMode: PathView.SnapOneItem
        highlightRangeMode: PathView.StrictlyEnforceRange
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        dragMargin: width / 2

        path: Path {
            startX: -view.width * 2
            startY: view.height / 2
            PathAttribute {
                name: "itemOpacity"
                value: 0.0
            }
            PathAttribute {
                name: "itemScale"
                value: 0.6
            }

            PathLine {
                x: -view.width * 0.5
                y: view.height / 2
            }
            PathPercent {
                value: 0.48
            }
            PathAttribute {
                name: "itemOpacity"
                value: 0.0
            }
            PathAttribute {
                name: "itemScale"
                value: 0.8
            }

            PathLine {
                x: view.width * 0.5
                y: view.height / 2
            }
            PathPercent {
                value: 0.5
            }
            PathAttribute {
                name: "itemOpacity"
                value: 1.0
            }
            PathAttribute {
                name: "itemScale"
                value: 1.0
            }

            PathLine {
                x: view.width * 1.5
                y: view.height / 2
            }
            PathPercent {
                value: 0.52
            }
            PathAttribute {
                name: "itemOpacity"
                value: 0.0
            }
            PathAttribute {
                name: "itemScale"
                value: 0.8
            }

            PathLine {
                x: view.width * 3
                y: view.height / 2
            }
            PathPercent {
                value: 1.0
            }
            PathAttribute {
                name: "itemOpacity"
                value: 0.0
            }
            PathAttribute {
                name: "itemScale"
                value: 0.6
            }
        }

        delegate: Item {
            id: delegateRoot
            width: view.width
            height: view.height
            opacity: PathView.itemOpacity
            scale: PathView.itemScale
            enabled: PathView.isCurrentItem
            
            readonly property alias tabLoaderRef: tabLoader

            Item {
                id: tabContainer
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                clip: true

                LazyContainer {
                    id: tabLoader
                    anchors.fill: parent
                    
                    active: {
                        let dist = Math.abs(index - view.currentIndex)
                        let circularDist = Math.min(dist, view.count - dist)
                        return circularDist <= 1
                    }

                    component: {
                        if (!model) {
                            return null
                        }
                        if (model.type === "timeDate") {
                            return timeDateComp
                        }
                        if (model.type === "music") {
                            return musicComp
                        }
                        if (model.type === "weather") {
                            return weatherComp
                        }
                        if (model.type === "battery") {
                            return batteryComp
                        }
                        if (model.type === "notif") {
                            return notifComp
                        }
                        if (model.type === "cc") {
                            return ccComp
                        }
                        if (model.type === "tray") {
                            return trayComp
                        }
                        return null
                    }
                }
            }
        }
    }

    Component {
        id: timeDateComp
        ClockDateDisplay { }
    }
    Component {
        id: musicComp
        MediaPlaybackView {
            mediaPlayer: logic ? logic.activePlayer : null
        }
    }
    Component {
        id: weatherComp
        WeatherDisplay { }
    }
    Component {
        id: batteryComp
        PowerStatusView { }
    }
    Component {
        id: notifComp
        NotificationTab { }
    }
    Component {
        id: ccComp
        SystemDashboard { }
    }
    Component {
        id: trayComp
        SystemTrayTab { }
    }

    Component.onCompleted: {
        if (logic) {
            logic.view = view
        }
    }
}
