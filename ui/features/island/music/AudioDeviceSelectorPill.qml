import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.core
import qs.ui.shared

ExpandingPill {
    id: root

    expandable: AudioManager.sinks.count > 0
    
    collapsedWidth: 85
    expandedWidth: 85
    collapsedHeight: 18
    expandedHeight: 44
    pillRadius: 9
    
    pillColor: Qt.rgba(1, 1, 1, 0.08)
    pillBorderColor: Qt.rgba(1, 1, 1, 0.1)

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 10
        spacing: 3

        StyledLabel {
            text: "󰓃"
            type: "caption"
            font.pixelSize: 8
            opacity: 0.6
        }

        StyledLabel {
            Layout.fillWidth: true
            text: AudioManager.defaultSink ? (AudioManager.defaultSink.description || AudioManager.defaultSink.name || "Device") : "No"
            type: "caption"
            font.pixelSize: 7
            font.weight: Font.Bold
            elideMode: Text.ElideRight
        }

        StyledLabel {
            text: root.isExpanded ? "󰅖" : "󱗘"
            type: "caption"
            font.pixelSize: 7
            opacity: 0.4
            visible: root.expandable
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.isExpanded
        opacity: root.isExpanded ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }

        ListView {
            id: deviceList
            anchors.fill: parent
            anchors.topMargin: 1
            anchors.bottomMargin: 1
            model: AudioManager.sinks
            spacing: 0
            clip: true
            interactive: true
            
            snapMode: ListView.SnapToItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: 20
            
            boundsBehavior: Flickable.StopAtBounds

            delegate: BaseButton {
                width: deviceList.width
                height: 20
                onClicked: {
                    AudioManager.selectSink(model.node)
                    root.isExpanded = false
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 4

                    StyledLabel {
                        text: "󰓄"
                        type: "caption"
                        font.pixelSize: 8
                        opacity: isHovered ? 0.8 : 0.4
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    StyledLabel {
                        Layout.fillWidth: true
                        text: model.name
                        type: "caption"
                        font.pixelSize: 7
                        elideMode: Text.ElideRight
                        opacity: isHovered ? 1.0 : 0.7
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }
            }
        }
    }
}
