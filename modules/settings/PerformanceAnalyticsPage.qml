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

        SmoothScrollBehavior {
            target: performanceScroll
        }
        ScrollEdgeFeedback {
            target: performanceScroll
        }
        ScrollBar.vertical: MinimalScrollBar {}

        ColumnLayout {
            id: content
            width: performanceScroll.width - 8
            spacing: 9

            SettingsHeader {
                title: "Performance"
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: root.metrics.available ? "Live process metrics" : "Metrics unavailable"
                    color: root.metrics.available ? Theme.textPrimary : Theme.textSecondary
                    font.family: Design.fontText
                    font.pixelSize: Design.typeBody
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.metrics.sampling ? "Reading…" : "Live"
                    color: Theme.textSecondary
                    font.family: Design.fontMono
                    font.pixelSize: Design.typeLabel
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Design.space12

                Repeater {
                    model: [
                        {
                            label: "RSS",
                            value: root.memoryText(root.metrics.rssKiB)
                        },
                        {
                            label: "PSS",
                            value: root.memoryText(root.metrics.pssKiB)
                        },
                        {
                            label: "Private",
                            value: root.memoryText(root.metrics.privateKiB)
                        }
                    ]

                    SettingMetric {
                        required property var modelData
                        Layout.fillWidth: true
                        label: modelData.label
                        value: modelData.value
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 132
                radius: Design.radiusGrouped
                color: Theme.fillSubtle
                border.width: 1
                border.color: Theme.separator

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    Text {
                        text: "Current memory composition"
                        color: Theme.textPrimary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeBody
                        font.weight: Font.DemiBold
                    }

                    MetricBarGraph {
                        Layout.fillWidth: true
                        metrics: [
                            {
                                label: "Anonymous",
                                value: root.toMiB(root.metrics.anonymousKiB),
                                color: Theme.accent
                            },
                            {
                                label: "Private",
                                value: root.toMiB(root.metrics.privateKiB),
                                color: Theme.success
                            },
                            {
                                label: "PSS",
                                value: root.toMiB(root.metrics.pssKiB),
                                color: Theme.warning
                            },
                            {
                                label: "RSS",
                                value: root.toMiB(root.metrics.rssKiB),
                                color: Theme.textSecondary
                            }
                        ]
                        unit: "M"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Design.space12

                Repeater {
                    model: [
                        {
                            label: "CPU",
                            value: root.metrics.cpuPercent >= 0 ? root.metrics.cpuPercent.toFixed(1) + "%" : "…"
                        },
                        {
                            label: "Threads",
                            value: String(root.metrics.threads)
                        },
                        {
                            label: "Displays",
                            value: String(root.metrics.screenCount)
                        },
                        {
                            label: "Uptime",
                            value: root.durationText(root.metrics.processUptimeSeconds)
                        }
                    ]

                    SettingMetric {
                        required property var modelData
                        Layout.fillWidth: true
                        label: modelData.label
                        value: modelData.value
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !root.metrics.available
                text: root.metrics.error
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeLabel
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                text: "RSS includes shared memory. PSS divides it among processes."
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeLabel
                wrapMode: Text.Wrap
            }
        }
    }

    function toMiB(kibibytes) {
        return Math.max(0, Number(kibibytes) || 0) / 1024;
    }

    function memoryText(kibibytes) {
        if (!metrics.available)
            return "—";
        return toMiB(kibibytes).toFixed(0) + " MiB";
    }

    function durationText(seconds) {
        const total = Math.max(0, Math.floor(Number(seconds) || 0));
        if (total >= 3600)
            return Math.floor(total / 3600) + "h";
        if (total >= 60)
            return Math.floor(total / 60) + "m";
        return total + "s";
    }
}
