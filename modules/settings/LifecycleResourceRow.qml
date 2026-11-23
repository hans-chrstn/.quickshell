import QtQuick
import QtQuick.Layouts
import qs.components.analytics
import qs.core

Rectangle {
    id: root

    required property var record
    required property string stateLabel
    required property color stateColor

    implicitHeight: 108
    radius: Design.radiusGrouped
    color: Theme.fillSubtle
    border.width: 1
    border.color: Theme.separator

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Text {
                Layout.fillWidth: true
                text: root.record.resourceId ?? "unknown"
                color: Theme.textPrimary
                font.family: Design.fontMono
                font.pixelSize: Design.typeLabel
                font.weight: Font.Medium
                elide: Text.ElideMiddle
            }

            Text {
                text: root.stateLabel
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeLabel
                font.weight: Font.DemiBold
            }
        }

        Text {
            Layout.fillWidth: true
            text: (root.record.classification ?? "unknown") + " · " + (root.record.owner ?? "no owner") + " · " + "req " + (root.record.requested ? "1" : "0") + " use " + (root.record.active ? "1" : "0") + " load " + (root.record.loaded ? "1" : "0") + (root.record.adaptiveEligible ? " · cost " + root.record.estimatedCostUnits + " · score " + Number(root.record.retentionScore ?? 0).toFixed(1) : "")
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeLabel
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: "load " + (root.record.loadCount ?? 0) + " / unload " + (root.record.unloadCount ?? 0) + " · active " + root.formatDuration(root.record.activeDurationMs ?? 0) + " · " + (root.record.retentionReason || root.record.evictionReason || "no transition reason")
            color: Theme.textSecondary
            font.family: Design.fontMono
            font.pixelSize: Design.typeLabel
            elide: Text.ElideRight
        }

        MetricBarGraph {
            Layout.fillWidth: true
            metrics: [
                {
                    label: "Last",
                    value: root.record.lastLoadDurationMs ?? 0,
                    color: Theme.success
                },
                {
                    label: "Avg",
                    value: root.record.averageLoadDurationMs ?? 0,
                    color: Theme.accent
                },
                {
                    label: "Peak",
                    value: root.record.maximumLoadDurationMs ?? 0,
                    color: Theme.warning
                }
            ]
            unit: "ms"
        }
    }

    function formatDuration(milliseconds) {
        const seconds = Math.max(0, Number(milliseconds) || 0) / 1000;
        if (seconds < 60)
            return seconds.toFixed(seconds < 10 ? 1 : 0) + "s";
        const minutes = Math.floor(seconds / 60);
        return minutes + "m " + Math.floor(seconds % 60) + "s";
    }
}
