import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Io
import qs.core
import qs.ui.shared

StyledCard {
    id: root

    property var streamData: null
    property bool isActive: false
    
    width: parent ? parent.width : 0
    height: 120

    readonly property int streamId: {
        return root.streamData ? root.streamData.id : -1
    }
    
    property int _routedSinkId: -1

    // Find the hardware device (sink/source) the stream is actually connected to via Pipewire linkGroups.
    readonly property PwNode linkedDeviceNode: {
        if (!Pipewire.ready || !Pipewire.linkGroups || !Pipewire.linkGroups.values) return null
        let lgs = Pipewire.linkGroups.values
        for (let i = 0; i < lgs.length; i++) {
            let lg = lgs[i]
            if (lg.source && lg.source.id === root.streamId) {
                if (lg.target && !lg.target.isStream) {
                    return lg.target
                }
            }
            if (lg.target && lg.target.id === root.streamId) {
                if (lg.source && lg.source.id !== root.streamId && !lg.source.isStream) {
                    return lg.source
                }
            }
        }
        return null
    }

    property PwNode currentTargetNode: {
        if (root._routedSinkId > 0 && AudioManager.sinks) {
            for (let i = 0; i < AudioManager.sinks.count; i++) {
                let sink = AudioManager.sinks.get(i)
                if (sink.id === root._routedSinkId) {
                    return sink.nodeObj
                }
            }
        }
        if (root.linkedDeviceNode) {
            return root.linkedDeviceNode
        }
        return (root.streamNode && root.streamNode.isSink) ? AudioManager.defaultSink : AudioManager.defaultSource
    }

    property int displayedTargetId: {
        if (root._routedSinkId > 0) {
            return root._routedSinkId
        }
        
        let linkedNode = root.linkedDeviceNode
        let defaultNode = (root.streamNode && root.streamNode.isSink) ? AudioManager.defaultSink : AudioManager.defaultSource
        
        if (linkedNode && defaultNode && linkedNode.id !== defaultNode.id) {
            return linkedNode.id
        }
        
        return -1
    }

    property bool isExplicitlyRouted: displayedTargetId > 0

    property var deviceModel: {
        let arr = [{ id: -1, name: "Default (Global)" }]
        let hwNodes = (root.streamNode && root.streamNode.isSink) ? AudioManager.sinks : AudioManager.sources
        if (hwNodes) {
            for (let i = 0; i < hwNodes.count; i++) {
                arr.push(hwNodes.get(i))
            }
        }
        return arr
    }

    readonly property string streamName: {
        return root.streamData ? (root.streamData.name || "Application") : "Application"
    }

    readonly property PwNode streamNode: {
        if (!root.isActive || !Pipewire.nodes || !Pipewire.nodes.values) {
            return null
        }

        let nodes = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            if (nodes[i] && nodes[i].id === root.streamId) {
                return nodes[i]
            }
        }
        return null
    }

    PwObjectTracker {
        objects: {
            if (root.streamNode && root.isActive) {
                return [root.streamNode]
            }
            return []
        }
    }

    Loader {
        id: nodeLoader
        anchors.fill: parent
        active: root.isActive && root.streamNode !== null

        sourceComponent: Item {
            anchors.fill: parent

            readonly property var nodeRef: root.streamNode
            
            readonly property real volumeValue: {
                if (nodeRef && nodeRef.ready && nodeRef.audio) {
                    return nodeRef.audio.volume
                }
                return 0.0
            }
            
            readonly property bool isMuted: {
                if (nodeRef && nodeRef.ready && nodeRef.audio) {
                    return !!nodeRef.audio.muted
                }
                return false
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledLabel {
                        text: (root.streamNode && root.streamNode.isSink) ? ThemeManager.iconAudioOutput : ThemeManager.iconAudioInput
                        type: "caption"
                        font.pixelSize: 12
                        opacity: 0.5
                    }

                    StyledLabel {
                        text: root.streamName
                        type: "label"
                        elideMode: Text.ElideRight
                        Layout.fillWidth: true
                    }

                }
                
                Process {
                    id: routeCmd
                    onExited: (exitCode) => {
                        if (exitCode !== 0) {
                            console.log("AudioStreamDelegate: routing failed, exit code:", exitCode)
                        }
                    }
                }

                ValueSlider {
                    Layout.fillWidth: true
                    sliderValue: parent.parent.volumeValue
                    sliderIcon: {
                        if (parent.parent.isMuted) {
                            return ThemeManager.iconMute
                        }
                        return ThemeManager.iconVolume
                    }
                    sliderBarColor: ThemeManager.accentColor
                    onSliderMoved: (val) => {
                        if (nodeRef && nodeRef.ready && nodeRef.audio) {
                            if (Math.abs(nodeRef.audio.volume - val) > 0.001) {
                                if (nodeRef.audio.muted && val > 0) {
                                    nodeRef.audio.muted = false
                                }
                                nodeRef.audio.volume = val
                            }
                            if (val === 0 && !nodeRef.audio.muted) {
                                nodeRef.audio.muted = true
                            }
                        }
                    }
                }
                
                DeviceSelectorDropdown {
                    Layout.fillWidth: true

                    icon: (root.streamNode && root.streamNode.isSink) ? ThemeManager.iconAudioOutput : ThemeManager.iconAudioInput
                    model: root.deviceModel
                    currentId: root.displayedTargetId

                    onDeviceSelected: (deviceId, deviceData) => {
                        routeCmd.running = false

                        let clientId = ""
                        if (root.streamNode && root.streamNode.properties) {
                            clientId = root.streamNode.properties["client.id"] || ""
                        }

                        if (deviceId === -1 || !deviceData) {
                            if (clientId) {
                                routeCmd.command = [
                                    "sh", "-c",
                                    "pw-metadata -n default " + root.streamId + " target.object - && pw-metadata -n default " + clientId + " target.object -"
                                ]
                            } else {
                                routeCmd.command = [
                                    "pw-metadata", "-n", "default",
                                    String(root.streamId),
                                    "target.object", "-"
                                ]
                            }
                            root._routedSinkId = -1
                        } else {
                            if (clientId) {
                                routeCmd.command = [
                                    "sh", "-c",
                                    "pw-metadata -n default " + root.streamId + " target.object " + deviceId + " Spa:Id && pw-metadata -n default " + clientId + " target.object " + deviceId + " Spa:Id"
                                ]
                            } else {
                                routeCmd.command = [
                                    "pw-metadata", "-n", "default",
                                    String(root.streamId),
                                    "target.object",
                                    String(deviceId), "Spa:Id"
                                ]
                            }
                            root._routedSinkId = deviceId
                        }
                        routeCmd.running = true
                    }
                }
            }
        }
    }

}
