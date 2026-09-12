import QtQuick
import QtQuick.Layouts
import qs.components.analytics
import qs.core

Rectangle {
    id: root

    required property var snapshot

    readonly property var plan: snapshot.cleanupPlan ?? ({})
    readonly property var cleanup: snapshot.cleanup ?? ({})
    readonly property var segments: [
        { label: "Posters", value: snapshot.posters?.bytes ?? 0,
          color: Design.blue },
        { label: "Optimized", value: snapshot.optimized?.bytes ?? 0,
          color: Design.green }
    ]

    implicitHeight: snapshot.scannedAt > 0 ? 132 : 66
    radius: 11
    color: Design.surface
    border.width: 1
    border.color: Design.separator

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "Cache composition"
                color: Design.text
                font.family: Design.fontText
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            Text {
                text: root.snapshot.scanning ? "Measuring…"
                    : root.snapshot.scannedAt > 0 ? "Measured" : "Not measured"
                color: root.snapshot.error ? Design.red : Design.textMuted
                font.family: Design.fontMono
                font.pixelSize: 7
            }
        }

        DonutChart {
            Layout.fillWidth: true
            visible: root.snapshot.scannedAt > 0
            diameter: 54
            strokeWidth: 7
            segments: root.segments
            centerValue: root.formatBytes(root.snapshot.totalBytes)
            centerLabel: "cached"
        }

        Text {
            Layout.fillWidth: true
            visible: root.snapshot.scannedAt <= 0
            text: root.snapshot.error ||
                "Open Wallpaper Cache once to measure; Analytics never starts scans."
            color: root.snapshot.error ? Design.red : Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 8
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            visible: root.snapshot.scannedAt > 0
            text: (root.snapshot.posters?.count ?? 0) + " posters · "
                + (root.snapshot.optimized?.count ?? 0) + " optimized · "
                + (root.plan.protectedCount ?? 0) + " protected · "
                + root.formatBytes(root.plan.reclaimBytes) + " reclaimable"
            color: Design.textMuted
            font.family: Design.fontMono
            font.pixelSize: 7
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            visible: root.snapshot.scannedAt > 0
                && (root.cleanup.state ?? "idle") !== "idle"
            text: root.cleanup.cleaning ? "Cleanup in progress"
                : (root.cleanup.deletedCount ?? 0) + " deleted · "
                    + (root.cleanup.skippedCount ?? 0) + " skipped · "
                    + root.formatBytes(root.cleanup.reclaimedBytes)
                    + " reclaimed"
            color: root.cleanup.error ? Design.red : Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 7
            elide: Text.ElideRight
        }
    }

    function formatBytes(value) {
        const bytes = Math.max(0, Number(value) || 0)
        if (bytes >= 1024 * 1024 * 1024)
            return (bytes / (1024 * 1024 * 1024)).toFixed(1) + "G"
        if (bytes >= 1024 * 1024)
            return (bytes / (1024 * 1024)).toFixed(0) + "M"
        if (bytes >= 1024)
            return (bytes / 1024).toFixed(0) + "K"
        return bytes + "B"
    }
}
