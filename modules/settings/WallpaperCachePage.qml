import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.config
import qs.services.settings
import qs.services.wallpaper

SettingPage {
    id: root

    function formattedBytes(value) {
        const bytes = Math.max(0, Number(value) || 0);
        if (bytes >= 1024 * 1024 * 1024)
            return (bytes / (1024 * 1024 * 1024)).toFixed(2) + " GiB";
        if (bytes >= 1024 * 1024)
            return (bytes / (1024 * 1024)).toFixed(1) + " MiB";
        if (bytes >= 1024)
            return (bytes / 1024).toFixed(1) + " KiB";
        return bytes + " B";
    }

    Component.onCompleted: WallpaperCacheService.scan()

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        SettingsHeader {
            title: "Cache"
        }

        SettingToggle {
            Layout.fillWidth: true
            title: "Automatic cleanup"
            description: "Remove unused files after wallpaper changes"
            checked: ConfigService.automaticWallpaperCacheCleanup
            onToggled: value => SettingsService.setSetting("automaticWallpaperCacheCleanup", value)
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: WallpaperCacheService.scanning ? "Measuring cache…" : WallpaperCacheService.error.length > 0 ? WallpaperCacheService.error : WallpaperCacheService.optimizedEntries.length + " optimized · " + root.formattedBytes(WallpaperCacheService.optimizedBytes) + "  |  " + WallpaperCacheService.posterEntries.length + " posters · " + root.formattedBytes(WallpaperCacheService.posterBytes)
                color: Theme.textSecondary
                font.family: Design.fontMono
                font.pixelSize: Design.typeLabel
                elide: Text.ElideRight
            }

            SettingButton {
                label: "Refresh"
                visible: !WallpaperCacheService.scanning && !WallpaperCacheService.cleaning
                onClicked: WallpaperCacheService.scan()
            }
        }

        Text {
            Layout.fillWidth: true
            text: WallpaperCacheService.scanning ? "Cleanup plan pending" : WallpaperCacheService.cleanupPlan.deleteCount + " removable · " + root.formattedBytes(WallpaperCacheService.cleanupPlan.reclaimBytes) + " · " + WallpaperCacheService.cleanupPlan.protectedCount + " protected"
            color: Theme.textSecondary
            font.family: Design.fontMono
            font.pixelSize: Design.typeLabel
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: WallpaperCacheService.cleaning ? "Cleaning unused files…" : WallpaperCacheService.cleanupState === "ready" ? WallpaperCacheService.deletedCount + " deleted · " + WallpaperCacheService.skippedCount + " skipped · " + root.formattedBytes(WallpaperCacheService.reclaimedBytes) + " reclaimed" : "Unused files, oldest first"
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeLabel
                elide: Text.ElideRight
            }

            SettingButton {
                label: "Clean Planned"
                dangerous: true
                visible: !WallpaperCacheService.cleaning && WallpaperCacheService.cleanupPlan.deleteCount > 0
                onClicked: WallpaperCacheService.executeCleanup()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.separator
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: {
                    if (WallpaperOptimizationService.clearState === "clearing")
                        return "Clearing all unassigned optimized copies…";
                    if (WallpaperOptimizationService.clearState === "ready")
                        return "Optimization cache cleared";
                    if (WallpaperOptimizationService.clearState === "failed")
                        return WallpaperOptimizationService.clearError;
                    if (WallpaperOptimizationService.hasAssignedOptimizedCopy())
                        return "Select original wallpapers before clearing all";
                    return "Remove optimized copies";
                }
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeBody
                wrapMode: Text.Wrap
            }

            SettingButton {
                label: "Clear All"
                dangerous: true
                enabled: WallpaperCacheService.optimizedEntries.length > 0
                visible: !WallpaperOptimizationService.clearing && !WallpaperCacheService.cleaning
                onClicked: {
                    if (WallpaperOptimizationService.clearCache())
                        cacheRefreshTimer.restart();
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    Timer {
        id: cacheRefreshTimer
        interval: 180
        onTriggered: WallpaperCacheService.scan()
    }
}
