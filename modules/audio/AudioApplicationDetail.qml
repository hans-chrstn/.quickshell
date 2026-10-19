import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.components.scrolling
import qs.core
import qs.services.audio
import "../../components/models/KeyedListReconciler.js" as KeyedListReconciler

Item {
    id: root

    required property var application
    signal backRequested

    readonly property var streams: Array.isArray(application?.streams) ? application.streams : []
    readonly property string displayName: String(application?.displayName || "Application")
    readonly property string directionLabel: application?.section === "recording" ? "Recording" : "Playing"
    readonly property string streamLabel: streams.length + (streams.length === 1 ? " stream" : " streams")

    function reconcileStreams() {
        KeyedListReconciler.reconcile(stableStreams, streams, "sessionId", "stream:");
    }

    onStreamsChanged: reconcileStreams()
    Component.onCompleted: reconcileStreams()

    ListModel {
        id: stableStreams

        dynamicRoles: true
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: Theme.fillSubtle
        border.width: 1
        border.color: Theme.separatorQuiet

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                spacing: 10

                GlyphButton {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    Layout.alignment: Qt.AlignVCenter
                    glyph: "chevronLeft"
                    glyphSize: 16
                    accessibleName: "Back to applications"
                    onActivated: root.backRequested()
                }

                AppIcon {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignVCenter
                    name: root.displayName
                    icon: String(root.application?.iconName || "")
                    iconSize: 36
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: root.displayName
                        color: Theme.textPrimary
                        font.family: Design.fontText
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.directionLabel + " · " + root.streamLabel
                        color: Theme.textTertiary
                        font.family: Design.fontText
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }

                Text {
                    Layout.preferredWidth: 180
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: String(root.application?.routeSummary || "Route unavailable")
                    color: Theme.textSecondary
                    font.family: Design.fontText
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.separator
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: streamList

                    anchors.fill: parent
                    anchors.rightMargin: 9
                    clip: true
                    model: stableStreams
                    reuseItems: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: MinimalScrollBar {}

                    SmoothScrollBehavior {
                        target: streamList
                        wheelStep: 62
                    }

                    delegate: Item {
                        id: streamRow

                        required property int index
                        required property string key
                        required property var record
                        readonly property var controlState: AudioService.applicationStreamControlState(root.application.key, record)
                        readonly property bool controllable: controlState?.ready === true && controlState?.capabilities?.volumeWrite === true && controlState?.capabilities?.muteWrite === true
                        width: streamList.width
                        height: 62

                        RowLayout {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            ColumnLayout {
                                Layout.preferredWidth: 104
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: "Stream " + (streamRow.index + 1)
                                    color: Theme.textPrimary
                                    font.family: Design.fontText
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: streamRow.controlState?.muted ? "Muted" : Math.round(Number(streamRow.controlState?.volume) * 100) + "%"
                                    color: streamRow.controlState?.muted ? Theme.textTertiary : Theme.textSecondary
                                    font.family: Design.fontMono
                                    font.pixelSize: 10
                                }
                            }

                            AudioLevelSlider {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                Layout.alignment: Qt.AlignVCenter
                                enabled: streamRow.controllable
                                from: 0
                                to: 1
                                value: Math.max(0, Math.min(1, Number(streamRow.controlState?.volume) || 0))
                                accentColor: streamRow.controlState?.muted ? Theme.textTertiary : Theme.textPrimary
                                Accessible.name: root.displayName + " stream " + (streamRow.index + 1) + " sound level"
                                onLevelEdited: value => AudioService.setApplicationStreamVolume(root.application.key, streamRow.key, value)
                                onStepRequested: steps => AudioService.adjustApplicationStreamVolume(root.application.key, streamRow.key, steps)
                            }

                            GlyphButton {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                Layout.alignment: Qt.AlignVCenter
                                enabled: streamRow.controllable
                                glyph: root.application.section === "recording" ? streamRow.controlState?.muted ? "microphoneMuted" : "microphone" : streamRow.controlState?.muted ? "volumeMuted" : "volumeHigh"
                                glyphSize: 19
                                primary: streamRow.controlState?.muted === true
                                accentColor: streamRow.controlState?.muted ? Theme.danger : Theme.textSecondary
                                accessibleName: (streamRow.controlState?.muted ? "Unmute " : "Mute ") + root.displayName + " stream " + (streamRow.index + 1)
                                onActivated: AudioService.setApplicationStreamMuted(root.application.key, streamRow.key, !streamRow.controlState?.muted)
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.bottom: parent.bottom
                            height: 1
                            visible: streamRow.index < root.streams.length - 1
                            color: Theme.separator
                        }
                    }
                }
            }
        }
    }
}
