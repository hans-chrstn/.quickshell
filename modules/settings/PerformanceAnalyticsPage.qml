import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components.analytics
import qs.components.scrolling
import qs.core
import qs.services.analytics

SettingPage {
    id: root

    readonly property var metrics: PerformanceAnalyticsService.snapshot()

    Component.onCompleted: PerformanceAnalyticsService.acquire()
    Component.onDestruction: PerformanceAnalyticsService.release()

    Flickable {
        id: performanceScroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        SmoothScrollBehavior { target: performanceScroll }
        ScrollEdgeFeedback { target: performanceScroll }
        ScrollBar.vertical: MinimalScrollBar {}

        ColumnLayout {
            id: content
            width: performanceScroll.width - 8
            spacing: 9

            SettingsHeader { title: "Performance" }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: root.metrics.available
                        ? "Live process metrics" : "Metrics unavailable"
                    color: root.metrics.available
                        ? Design.green : Design.yellow
                    font.family: Design.fontText
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.metrics.sampling ? "Reading…" : "Live"
                    color: Design.textMuted
                    font.family: Design.fontMono
                    font.pixelSize: 8
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { label: "RSS", value: root.memoryText(
                            root.metrics.rssKiB) },
                        { label: "PSS", value: root.memoryText(
                            root.metrics.pssKiB) },
                        { label: "Private", value: root.memoryText(
                            root.metrics.privateKiB) }
                    ]

                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 9
                        color: Design.surface
                        border.width: 1
                        border.color: Design.separator

                        Column {
                            anchors.centerIn: parent

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                color: Design.text
                                font.family: Design.fontMono
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: Design.textMuted
                                font.family: Design.fontText
                                font.pixelSize: 7
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 92
                radius: 11
                color: Design.surface
                border.width: 1
                border.color: Design.separator

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    Text {
                        text: "Current memory composition"
                        color: Design.text
                        font.family: Design.fontText
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    MetricBarGraph {
                        Layout.fillWidth: true
                        metrics: [
                            { label: "Anonymous", value: root.toMiB(
                                root.metrics.anonymousKiB), color: Design.blue },
                            { label: "Private", value: root.toMiB(
                                root.metrics.privateKiB), color: Design.green },
                            { label: "PSS", value: root.toMiB(
                                root.metrics.pssKiB), color: Design.yellow },
                            { label: "RSS", value: root.toMiB(
                                root.metrics.rssKiB), color: Design.textMuted }
                        ]
                        unit: "M"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { label: "CPU", value: root.metrics.cpuPercent >= 0
                            ? root.metrics.cpuPercent.toFixed(1) + "%" : "…" },
                        { label: "Threads", value: String(root.metrics.threads) },
                        { label: "Displays", value: String(
                            root.metrics.screenCount) },
                        { label: "Uptime", value: root.durationText(
                            root.metrics.processUptimeSeconds) }
                    ]

                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 9
                        color: Design.surface
                        border.width: 1
                        border.color: Design.separator

                        Column {
                            anchors.centerIn: parent

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                color: Design.text
                                font.family: Design.fontMono
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: Design.textMuted
                                font.family: Design.fontText
                                font.pixelSize: 7
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !root.metrics.available
                text: root.metrics.error
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 8
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                text: "RSS includes shared and file-backed mappings. PSS apportions shared memory; neither value alone proves a leak."
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 8
                wrapMode: Text.Wrap
            }
        }
    }

    function toMiB(kibibytes) {
        return Math.max(0, Number(kibibytes) || 0) / 1024
    }

    function memoryText(kibibytes) {
        if (!metrics.available)
            return "—"
        return toMiB(kibibytes).toFixed(0) + " MiB"
    }

    function durationText(seconds) {
        const total = Math.max(0, Math.floor(Number(seconds) || 0))
        if (total >= 3600)
            return Math.floor(total / 3600) + "h"
        if (total >= 60)
            return Math.floor(total / 60) + "m"
        return total + "s"
    }
}
