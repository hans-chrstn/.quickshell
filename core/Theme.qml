pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color islandCollapsed: "#f2050505"
    readonly property color islandExpanded: islandCollapsed
    readonly property color overlay: "#f01c1c1c"
    readonly property color wallpaperFallback: "#000000"
    readonly property color scrim: "#52000000"
    readonly property color shadow: "#b3000000"
    readonly property color controlShadow: "#3d000000"

    readonly property color glassStroke: "#18ffffff"
    readonly property color glassHighlight: "#2affffff"
    readonly property color glassShade: "#52000000"

    readonly property color fillFaint: "#05ffffff"
    readonly property color fillQuiet: "#09ffffff"
    readonly property color fillSubtle: "#0dffffff"
    readonly property color fillElevated: "#17ffffff"
    readonly property color fillSelected: "#1cffffff"
    readonly property color fillStrong: "#24ffffff"

    readonly property color controlFill: fillSubtle
    readonly property color controlHover: fillElevated
    readonly property color controlPressed: fillStrong

    readonly property color textPrimary: "#f5f5f7"
    readonly property color textSecondary: "#b3b3b8"
    readonly property color textTertiary: "#7d7d83"
    readonly property color textDisabled: "#61f5f5f7"

    readonly property color separatorQuiet: "#0cffffff"
    readonly property color separator: "#16ffffff"
    readonly property color separatorStrong: "#26ffffff"

    readonly property color accent: "#0a84ff"
    readonly property color success: "#30d158"
    readonly property color warning: "#ffd60a"
    readonly property color privacy: "#ff9f0a"
    readonly property color danger: "#ff453a"

    function alpha(color, opacity) {
        return Qt.rgba(color.r, color.g, color.b, Math.max(0, Math.min(1, opacity)));
    }

    function tintSubtle(color) {
        return alpha(color, 0.10);
    }

    function tint(color) {
        return alpha(color, 0.16);
    }

    function tintStrong(color) {
        return alpha(color, 0.24);
    }

    function tintActive(color) {
        return alpha(color, 0.20);
    }

    function tintHover(color) {
        return alpha(color, 0.28);
    }

    function tintPressed(color) {
        return alpha(color, 0.34);
    }

    function tintBorder(color) {
        return alpha(color, 0.42);
    }

    function tintLine(color) {
        return alpha(color, 0.58);
    }

    function tintGuide(color) {
        return alpha(color, 0.48);
    }

    function tintOpaque(color) {
        return alpha(color, 0.86);
    }

    function mix(first, second, progress) {
        const amount = Math.max(0, Math.min(1, progress));
        return Qt.rgba(first.r + (second.r - first.r) * amount, first.g + (second.g - first.g) * amount, first.b + (second.b - first.b) * amount, first.a + (second.a - first.a) * amount);
    }
}
