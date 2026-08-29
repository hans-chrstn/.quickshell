import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.config
import qs.services.settings
import qs.services.wallpaper

SettingPage {
    id: root

    function formattedBytes(value) {
        const bytes = Math.max(0, Number(value) || 0)
        if (bytes >= 1024 * 1024 * 1024)
            return (bytes / (1024 * 1024 * 1024)).toFixed(2) + " GiB"
        if (bytes >= 1024 * 1024)
            return (bytes / (1024 * 1024)).toFixed(1) + " MiB"
        if (bytes >= 1024)
            return (bytes / 1024).toFixed(1) + " KiB"
        return bytes + " B"
    }

    Component.onCompleted: WallpaperCacheService.scan()

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        SettingsHeader { title: "Cache" }

        SettingToggle {
            Layout.fillWidth: true
            title: "Automatic bounded cleanup"
            description: "Clean stale unprotected cache after media changes"
            checked: ConfigService.automaticWallpaperCacheCleanup
            onToggled: value => SettingsService.setSetting(
                "automaticWallpaperCacheCleanup", value)
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: WallpaperCacheService.scanning ? "Measuring cache…"
                    : WallpaperCacheService.error.length > 0
                        ? WallpaperCacheService.error
                        : WallpaperCacheService.optimizedEntries.length
                            + " optimized · "
                            + root.formattedBytes(
                                WallpaperCacheService.optimizedBytes)
                            + "  |  "
                            + WallpaperCacheService.posterEntries.length
                            + " posters · "
                            + root.formattedBytes(
                                WallpaperCacheService.posterBytes)
                color: WallpaperCacheService.error.length > 0
                    ? Design.red : Design.textMuted
                font.family: Design.fontMono
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            SettingButton {
                label: "Refresh"
                visible: !WallpaperCacheService.scanning
                    && !WallpaperCacheService.cleaning
                onClicked: WallpaperCacheService.scan()
            }
        }

        Text {
            Layout.fillWidth: true
            text: WallpaperCacheService.scanning ? "Cleanup plan pending"
                : WallpaperCacheService.cleanupPlan.deleteCount
                    + " removable · "
                    + root.formattedBytes(
                        WallpaperCacheService.cleanupPlan.reclaimBytes)
                    + " · "
                    + WallpaperCacheService.cleanupPlan.protectedCount
                    + " protected"
            color: Design.textMuted
            font.family: Design.fontMono
            font.pixelSize: 9
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: WallpaperCacheService.cleaning
                    ? "Revalidating and cleaning planned entries…"
                    : WallpaperCacheService.cleanupState === "ready"
                        ? WallpaperCacheService.deletedCount + " deleted · "
                            + WallpaperCacheService.skippedCount + " skipped · "
                            + root.formattedBytes(
                                WallpaperCacheService.reclaimedBytes)
                            + " reclaimed"
                        : "Oldest unprotected files are selected first"
                color: WallpaperCacheService.cleanupError.length > 0
                    ? Design.red : Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            SettingButton {
                label: "Clean Planned"
                dangerous: true
                visible: !WallpaperCacheService.cleaning
                    && WallpaperCacheService.cleanupPlan.deleteCount > 0
                onClicked: WallpaperCacheService.executeCleanup()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Design.separator
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: {
                    if (WallpaperOptimizationService.clearState === "clearing")
                        return "Clearing all unassigned optimized copies…"
                    if (WallpaperOptimizationService.clearState === "ready")
                        return "Optimization cache cleared"
                    if (WallpaperOptimizationService.clearState === "failed")
                        return WallpaperOptimizationService.clearError
                    if (WallpaperOptimizationService.hasAssignedOptimizedCopy())
                        return "Select original wallpapers before clearing all"
                    return "Manual clear removes every optimized derivative"
                }
                color: WallpaperOptimizationService.clearState === "failed"
                    ? Design.red : Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 9
                wrapMode: Text.Wrap
            }

            SettingButton {
                label: "Clear All"
                dangerous: true
                visible: !WallpaperOptimizationService.clearing
                    && !WallpaperCacheService.cleaning
                onClicked: {
                    if (WallpaperOptimizationService.clearCache())
                        cacheRefreshTimer.restart()
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    Timer {
        id: cacheRefreshTimer
        interval: 180
        onTriggered: WallpaperCacheService.scan()
    }
}
