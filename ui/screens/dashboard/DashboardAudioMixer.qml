import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared
import qs.ui.screens.dashboard.audiomixer
import Quickshell

ColumnLayout {
    id: root

    property bool active: false

    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

    StyledLabel {
        text: "Audio Mixer"
        type: "heading"
        font.pixelSize: 28
    }
    
    Loader {
        id: mixerLoader
        Layout.fillWidth: true
        Layout.fillHeight: true
        asynchronous: true
        active: root.active || item !== null
        
        sourceComponent: ColumnLayout {
            anchors.fill: parent
            spacing: 25
            
            DefaultDeviceSelector {
                Layout.fillWidth: true
                active: root.active
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: ThemeManager.outlinePrimaryColor
                opacity: 0.5
            }
            
            StyledLabel {
                text: "Application Volumes"
                type: "label"
                font.weight: Font.Bold
                opacity: 0.8
            }

            ListView {
                id: streamList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: AudioManager ? AudioManager.streams : null
                spacing: 15
                clip: true

                delegate: AudioStreamDelegate {
                    streamData: model
                    isActive: root.active
                }

                StyledLabel {
                    text: "No active application streams"
                    type: "caption"
                    opacity: 0.3
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: AudioManager && AudioManager.streams && AudioManager.streams.count === 0
                }
            }
        }
    }
}
