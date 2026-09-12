import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components.analytics
import qs.components.scrolling
import qs.core
import qs.services.wallpaper

SettingPage {
    id: root

    property var snapshot: ({ screens: ({}) })
    property var cacheSnapshot: ({ scannedAt: 0, posters: ({}),
        optimized: ({}), cleanupPlan: ({}), cleanup: ({}) })

    readonly property var rows: Object.keys(snapshot.screens ?? {})
        .sort().map(name => ({ name: name, record: snapshot.screens[name] }))

    readonly property var stateSegments: {
        let staticCount = 0
        let playing = 0
        let paused = 0
        let evicted = 0
        let empty = 0
        let failed = 0
        for (let index = 0; index < rows.length; ++index) {
            const record = rows[index].record
            if (!record.path)
                ++empty
            else if (record.error || record.rendererState === "error")
                ++failed
            else if (record.kind === "static")
                ++staticCount
            else if (record.playbackActive)
                ++playing
            else if (record.decoderEvicted)
                ++evicted
            else
                ++paused
        }
        return [
            { label: "Static", value: staticCount, color: Design.blue },
            { label: "Playing", value: playing, color: Design.green },
            { label: "Paused", value: paused, color: Design.yellow },
            { label: "Evicted", value: evicted, color: Design.textMuted },
            { label: "Empty", value: empty, color: Design.surfaceRaised },
            { label: "Error", value: failed, color: Design.red }
        ]
    }

    readonly property string observerMessage: {
        const messages = []
        const occlusionError = String(snapshot.occlusionObserver?.error || "")
        const powerError = String(snapshot.monitorPowerObserver?.error || "")
        const battery = snapshot.power ?? ({})
        if (occlusionError) messages.push("Occlusion: " + occlusionError)
        if (powerError) messages.push("Monitor power: " + powerError)
        if (battery.optionEnabled && !battery.available)
            messages.push("Battery state unavailable")
        return messages.join(" · ")
    }

    function stateLabel(record) {
        if (!record.path) return "Empty"
        if (record.error || record.rendererState === "error") return "Error"
        if (record.kind === "static") return "Static"
        if (record.playbackActive) return "Playing"
        if (record.decoderEvicted) return "Evicted"
        if (record.suspended) return "Paused"
        return record.rendererState || "Unknown"
    }

    function stateColor(record) {
        if (!record.path) return Design.textMuted
        if (record.error || record.rendererState === "error") return Design.red
        if (record.kind === "static") return Design.blue
        if (record.playbackActive) return Design.green
        if (record.decoderEvicted) return Design.textMuted
        if (record.suspended) return Design.yellow
        return record.error ? Design.red : Design.textMuted
    }

    function refresh() {
        snapshot = WallpaperDiagnosticsService.snapshot()
        cacheSnapshot = WallpaperCacheService.snapshot()
    }

    function refreshCache() {
        cacheSnapshot = WallpaperCacheService.snapshot()
    }

    Component.onCompleted: refresh()

    Connections {
        target: WallpaperRenderService
        function onScreensChanged() { root.refresh() }
    }

    Connections {
        target: WallpaperProbeService
        function onRecordsChanged() { root.refresh() }
    }

    Connections {
        target: WallpaperOptimizationService
        function onRecordsChanged() { root.refresh() }
    }

    Connections {
        target: WallpaperCacheService
        function onEntriesChanged() { root.refreshCache() }
        function onCleanupPlanChanged() { root.refreshCache() }
        function onScanningChanged() { root.refreshCache() }
        function onCleanupStateChanged() { root.refreshCache() }
        function onCleaningChanged() { root.refreshCache() }
        function onReclaimedBytesChanged() { root.refreshCache() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        SettingsHeader { title: "Wallpaper" }

        DonutChart {
            Layout.fillWidth: true
            segments: root.stateSegments
            centerValue: root.rows.length
            centerLabel: root.rows.length === 1 ? "display" : "displays"
        }

        Text {
            Layout.fillWidth: true
            visible: root.observerMessage.length > 0
            text: root.observerMessage
            color: Design.red
            font.family: Design.fontText
            font.pixelSize: 8
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            text: "Live renderer state"
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 8
            font.weight: Font.Medium
        }

        ListView {
            id: displayList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.rows
            boundsBehavior: Flickable.StopAtBounds

            SmoothScrollBehavior { target: displayList }
            ScrollEdgeFeedback { target: displayList }
            ScrollBar.vertical: MinimalScrollBar {}

            footer: Component {
                Item {
                    width: displayList.width - 8
                    height: cacheCard.implicitHeight + 10

                    WallpaperCacheAnalyticsCard {
                        id: cacheCard
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        snapshot: root.cacheSnapshot
                    }
                }
            }

            delegate: WallpaperAnalyticsRow {
                required property var modelData
                width: displayList.width - 8
                screenName: modelData.name
                record: modelData.record
                stateLabel: root.stateLabel(modelData.record)
                stateColor: root.stateColor(modelData.record)
            }
        }
    }
}
