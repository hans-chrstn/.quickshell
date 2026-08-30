import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components.analytics
import qs.components.scrolling
import qs.core
import qs.services.analytics

SettingPage {
    id: root

    readonly property var evidence: PerformanceEvidenceService.snapshot()
    readonly property var modest: evidence.constructionProfiles.modest
    readonly property var stress: evidence.constructionProfiles.stress
    readonly property var memoryBaseline: evidence.staticBaseline
    readonly property var attribution: evidence.attribution

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
                text: "Observed evidence"
                color: Design.green
                font.family: Design.fontText
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }

            Text {
                text: "No live sampling"
                color: Design.textMuted
                font.family: Design.fontMono
                font.pixelSize: 8
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 86
            radius: 11
            color: Design.surface
            border.width: 1
            border.color: Design.separator

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: "Construction latency"
                        color: Design.text
                        font.family: Design.fontText
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "desktop → stress"
                        color: Design.textMuted
                        font.family: Design.fontMono
                        font.pixelSize: 7
                    }
                }

                ComparisonBarGraph {
                    Layout.fillWidth: true
                    metrics: [
                        { label: "Launcher", before: root.modest.launcherMs,
                          after: root.stress.launcherMs,
                          beforeText: root.modest.launcherMs + "ms",
                          afterText: root.stress.launcherMs + "ms" },
                        { label: "Settings", before: root.modest.settingsMs,
                          after: root.stress.settingsMs,
                          beforeText: root.modest.settingsMs + "ms",
                          afterText: root.stress.settingsMs + "ms" },
                        { label: "Wallpaper", before: root.modest.wallpaperMs,
                          after: root.stress.wallpaperMs,
                          beforeText: root.modest.wallpaperMs + "ms",
                          afterText: root.stress.wallpaperMs + "ms" }
                    ]
                    beforeColor: Design.blue
                    afterColor: Design.yellow
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { label: "RSS", value: root.formatMiB(
                        root.memoryBaseline.rssKiB) },
                    { label: "PSS", value: root.formatMiB(
                        root.memoryBaseline.pssKiB) },
                    { label: "Private", value: root.formatMiB(
                        root.memoryBaseline.privateAnonymousKiB) }
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
                        spacing: 0

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

        Text {
            Layout.fillWidth: true
            text: root.memoryBaseline.label + " · "
                + root.memoryBaseline.measurement
            color: Design.textMuted
            font.family: Design.fontMono
            font.pixelSize: 7
            wrapMode: Text.Wrap
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 84
            radius: 11
            color: Design.surface
            border.width: 1
            border.color: Design.separator

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                Text {
                    Layout.fillWidth: true
                    text: "Private memory by composition"
                    color: Design.text
                    font.family: Design.fontText
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                MetricBarGraph {
                    Layout.fillWidth: true
                    metrics: [
                        { label: "Core", value: root.toMiB(
                            root.attribution.structuralKiB),
                          color: Design.textMuted },
                        { label: "Islands", value: root.toMiB(
                            root.attribution.islandWindowsKiB),
                          color: Design.blue },
                        { label: "Walls", value: root.toMiB(
                            root.attribution.wallpaperWindowsKiB),
                          color: Design.green },
                        { label: "Full", value: root.toMiB(
                            root.attribution.fullShellKiB),
                          color: Design.yellow }
                    ]
                    unit: "M"
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Separate clean runs · compositions overlap and are not additive"
            color: Design.textMuted
            font.family: Design.fontMono
            font.pixelSize: 7
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            text: root.evidence.limitation
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 8
            wrapMode: Text.Wrap
        }

        }
    }

    function formatMiB(kibibytes) {
        return (Number(kibibytes) / 1024).toFixed(0) + " MiB"
    }

    function toMiB(kibibytes) {
        return Number(kibibytes) / 1024
    }
}
