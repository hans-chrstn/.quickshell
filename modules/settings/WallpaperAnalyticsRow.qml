import QtQuick
import QtQuick.Layouts
import qs.components.analytics
import qs.core

Rectangle {
    id: root

    required property string screenName
    required property var record
    required property string stateLabel
    required property color stateColor

    readonly property var optimization: record.optimization ?? ({})
    readonly property bool showComparison: optimization.available

    implicitHeight: showComparison ? 138 : 86
    radius: 10
    color: Design.surface
    border.width: 1
    border.color: Design.separator

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 9
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Text {
                Layout.fillWidth: true
                text: root.screenName
                color: Design.text
                font.family: Design.fontText
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            Rectangle {
                Layout.preferredWidth: stateText.implicitWidth + 10
                Layout.preferredHeight: 16
                radius: 8
                color: Qt.rgba(root.stateColor.r, root.stateColor.g,
                    root.stateColor.b, 0.14)
                border.width: 1
                border.color: Qt.rgba(root.stateColor.r, root.stateColor.g,
                    root.stateColor.b, 0.42)

                Text {
                    id: stateText
                    anchors.centerIn: parent
                    text: root.stateLabel
                    color: root.stateColor
                    font.family: Design.fontText
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.mediaSummary()
            color: Design.textMuted
            font.family: Design.fontMono
            font.pixelSize: 8
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.record.path || "No wallpaper assigned"
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 8
            elide: Text.ElideMiddle
        }

        Text {
            Layout.fillWidth: true
            text: root.runtimeSummary()
            color: root.record.error ? Design.red : Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 8
            elide: Text.ElideRight
        }

        ComparisonBarGraph {
            Layout.fillWidth: true
            visible: root.showComparison
            metrics: root.comparisonMetrics()
        }

        Text {
            Layout.fillWidth: true
            visible: !root.showComparison
                && root.optimization.applied
            text: root.optimization.mappingKnown
                ? "Optimized metadata is unavailable"
                : "Original mapping unavailable after restart"
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 7
            elide: Text.ElideRight
        }
    }

    function mediaSummary() {
        const media = record.media ?? ({})
        const geometry = media.width > 0 && media.height > 0
            ? media.width + "×" + media.height : "size unknown"
        const fps = media.frameRate > 0
            ? " · " + Number(media.frameRate).toFixed(0) + " fps" : ""
        const codec = media.codec ? " · " + String(media.codec).toUpperCase() : ""
        return geometry + fps + codec
    }

    function runtimeSummary() {
        if (record.error)
            return record.error
        if (record.kind === "static")
            return "Direct image · monitor "
                + (record.monitorPowered ? "powered" : "off")
        let decoder = record.decoderEvicted ? "Decoder evicted"
            : record.decoderLoaded ? "Decoder loaded" : "Decoder idle"
        const reason = record.suspendedReason
            ? " · " + record.suspendedReason : ""
        return decoder + reason + " · active "
            + formatDuration(record.activeDurationMs)
    }

    function formatDuration(milliseconds) {
        const seconds = Math.max(0, Number(milliseconds) || 0) / 1000
        if (seconds < 60)
            return seconds.toFixed(seconds < 10 ? 1 : 0) + "s"
        return Math.floor(seconds / 60) + "m "
            + Math.floor(seconds % 60) + "s"
    }

    function comparisonMetrics() {
        const source = optimization.sourceMedia ?? ({})
        const output = optimization.outputMedia ?? ({})
        return [
            {
                label: "Pixels",
                before: Number(source.width) * Number(source.height),
                after: Number(output.width) * Number(output.height),
                beforeText: dimensions(source),
                afterText: dimensions(output)
            },
            {
                label: "Frame rate",
                before: Number(source.frameRate) || 0,
                after: Number(output.frameRate) || 0,
                beforeText: rounded(source.frameRate) + " fps",
                afterText: rounded(output.frameRate) + " fps"
            },
            {
                label: "Bitrate",
                before: Number(source.bitRate) || 0,
                after: Number(output.bitRate) || 0,
                beforeText: megabits(source.bitRate),
                afterText: megabits(output.bitRate)
            }
        ]
    }

    function dimensions(media) {
        return Number(media.width) > 0 && Number(media.height) > 0
            ? media.width + "×" + media.height : "unknown"
    }

    function rounded(value) {
        return Number(value) > 0 ? Number(value).toFixed(0) : "?"
    }

    function megabits(value) {
        return Number(value) > 0
            ? (Number(value) / 1000000).toFixed(1) + "M" : "unknown"
    }
}
