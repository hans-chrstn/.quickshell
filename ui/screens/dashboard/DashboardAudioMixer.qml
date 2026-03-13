import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.core
import qs.ui.shared

ColumnLayout {
    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

    StyledLabel {
        text: "Audio Mixer"
        type: "heading"
        font.pixelSize: 28
    }

    ListView {
        id: streamList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: AudioManager.streams
        spacing: 15
        clip: true

        delegate: StyledCard {
            id: delegateRoot
            width: streamList.width
            height: 80

            readonly property int streamId: model.id
            readonly property string streamName: model.name || "Application"
            readonly property bool isActuallyVisible: DashboardManager.active

            readonly property PwNode streamNode: {
                if (!DashboardManager.realActive || !Pipewire.nodes || !Pipewire.nodes.values) {
                    return null;
                }

                let nodes = Pipewire.nodes.values;
                for (let i = 0; i < nodes.length; i++) {
                    if (nodes[i] && nodes[i].id === delegateRoot.streamId) {
                        return nodes[i];
                    }
                }
                return null;
            }

            PwObjectTracker {
                objects: (delegateRoot.streamNode && delegateRoot.isActuallyVisible) 
                    ? [delegateRoot.streamNode] 
                    : []
            }

            Loader {
                anchors.fill: parent
                active: {
                    let n = delegateRoot.streamNode;
                    return delegateRoot.isActuallyVisible 
                        && n !== null 
                        && n !== undefined 
                        && n.ready 
                        && n.audio !== undefined;
                }

                sourceComponent: Item {
                    anchors.fill: parent

                    readonly property var nodeRef: delegateRoot.streamNode
                    readonly property real vol: (nodeRef && nodeRef.ready && nodeRef.audio) 
                        ? nodeRef.audio.volume 
                        : 0.0
                    readonly property bool isMuted: (nodeRef && nodeRef.ready && nodeRef.audio) 
                        ? nodeRef.audio.muted 
                        : false

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true

                            StyledLabel {
                                text: delegateRoot.streamName
                                type: "label"
                                elideMode: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledLabel {
                                text: Math.round(vol * 100) + "%"
                                type: "pillValue"
                                opacity: 0.6
                            }
                        }

                        ValueSlider {
                            Layout.fillWidth: true
                            sliderValue: vol
                            sliderIcon: isMuted 
                                ? ThemeManager.iconMute 
                                : ThemeManager.iconVolume
                            sliderBarColor: ThemeManager.accentColor
                            onSliderMoved: (val) => {
                                if (nodeRef && nodeRef.ready && nodeRef.audio) {
                                    nodeRef.audio.volume = val
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
                    visible: delegateRoot.isActuallyVisible 
                        && (!delegateRoot.streamNode || !delegateRoot.streamNode.ready || !delegateRoot.streamNode.audio)
                }
            }
        }

        StyledLabel {
            text: "No active application streams"
            type: "caption"
            opacity: 0.3
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: AudioManager.streams.count === 0
        }
    }
}
