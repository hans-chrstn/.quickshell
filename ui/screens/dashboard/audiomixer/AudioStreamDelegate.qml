import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.core
import qs.ui.shared

StyledCard {
    id: root

    property var streamData: null
    property bool isActive: false
    
    width: parent ? parent.width : 0
    height: 80

    readonly property int streamId: {
        return root.streamData ? root.streamData.id : -1
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
        active: {
            let n = root.streamNode
            return root.isActive 
                && n !== null 
                && n !== undefined 
                && n.ready 
                && n.audio !== undefined
        }

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

                    StyledLabel {
                        text: root.streamName
                        type: "label"
                        elideMode: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledLabel {
                        text: {
                            return Math.round(parent.parent.parent.volumeValue * 100) + "%"
                        }
                        type: "pillValue"
                        opacity: 0.6
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
                            nodeRef.audio.volume = val
                        }
                    }
                }
            }
        }
    }

    StyledLabel {
        anchors.centerIn: parent
        text: "Synchronizing..."
        type: "caption"
        opacity: 0.3
        visible: {
            if (!root.isActive) {
                return false
            }
            return !root.streamNode || !root.streamNode.ready || !root.streamNode.audio
        }
    }
}
