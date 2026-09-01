import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.config
import qs.services.wallpaper

Rectangle {
    id: root

    required property var assessment
    readonly property int severity: Number(assessment?.severity) || 0
    readonly property var issues: assessment?.issues || []
    readonly property var optimization:
        WallpaperOptimizationService.recordFor(assessment?.path || "")
    readonly property bool optimizedCopyAvailable:
        WallpaperOptimizationService.currentCopyAvailable(
            assessment?.target || "", assessment?.path || "")
    readonly property bool optimizedCopyApplied:
        WallpaperOptimizationService.currentCopyApplied(
            assessment?.target || "", assessment?.path || "")

    implicitHeight: content.implicitHeight + 20
    radius: 10
    color: Design.surface
    border.width: 1
    border.color: severity >= 2 ? Design.red
        : severity === 1 ? Design.yellow : Design.separator

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 3

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: String(root.assessment?.target || "Wallpaper")
                color: Design.text
                font.family: Design.fontText
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.assessment?.state !== "ready" ? "Unavailable"
                    : root.severity >= 2 ? "High cost"
                    : root.severity === 1 ? "Review" : "Recommended"
                color: root.assessment?.state !== "ready" ? Design.textMuted
                    : root.severity >= 2 ? Design.red
                    : root.severity === 1 ? Design.yellow : Design.green
                font.family: Design.fontText
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }

        Text {
            Layout.fillWidth: true
            text: {
                const value = root.assessment || ({})
                if (["unknown", "queued", "probing"].indexOf(value.state) >= 0)
                    return "Inspecting media metadata…"
                if (value.state !== "ready") return "Media metadata is unavailable"
                if (value.kind !== "video") return "Static media · no decoder cost"
                const rate = value.frameRate > 0
                    ? " · " + value.frameRate.toFixed(1) + " FPS" : ""
                const bitrate = value.bitRate > 0
                    ? " · " + (value.bitRate / 1000000).toFixed(1) + " Mbps" : ""
                return value.width + "×" + value.height + rate + bitrate
                    + (value.codec ? " · " + value.codec.toUpperCase() : "")
            }
            color: Design.textMuted
            font.family: Design.fontMono
            font.pixelSize: 9
            elide: Text.ElideRight
        }

        Repeater {
            model: root.issues

            Text {
                required property string modelData
                Layout.fillWidth: true
                text: "• " + modelData
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 9
                wrapMode: Text.Wrap
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.assessment?.kind === "video"

            Text {
                Layout.fillWidth: true
                text: {
                    const state = String(root.optimization?.state || "idle")
                    if (WallpaperOptimizationService.isOptimizedPath(
                            root.assessment?.path || ""))
                        return "Using a performance-optimized cache copy"
                    if (!ConfigService.allowWallpaperOptimization)
                        return "Optimization is disabled in Wallpaper Options"
                    if (state === "optimizing") return "Creating optimized copy…"
                    if (state === "preparing" || state === "checking"
                            || state === "inspecting")
                        return "Checking optimized copy…"
                    if (root.optimizedCopyApplied)
                        return "Optimized copy applied"
                    if (root.optimizedCopyAvailable)
                        return "Optimized copy available"
                    if (state === "failed" || state === "cancelled")
                        return String(root.optimization?.error || "Optimization failed")
                    return "Preserves the original · display-sized H.264 · 30 FPS"
                }
                color: root.optimization?.state === "failed"
                    ? Design.red : Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 9
                wrapMode: Text.Wrap
            }

            SettingButton {
                visible: !WallpaperOptimizationService.busy
                    && ConfigService.allowWallpaperOptimization
                    && !root.optimizedCopyApplied
                    && !WallpaperOptimizationService.isOptimizedPath(
                        root.assessment?.path || "")
                label: root.optimizedCopyAvailable
                    ? "Use Optimized" : "Optimize & Use"
                onClicked: WallpaperOptimizationService.request(
                    String(root.assessment?.target || ""),
                    String(root.assessment?.path || ""))
            }

            SettingButton {
                visible: WallpaperOptimizationService.busy
                    && WallpaperOptimizationService.activeSource
                        === String(root.assessment?.path || "")
                label: "Cancel"
                onClicked: WallpaperOptimizationService.cancel()
            }
        }
    }
}
