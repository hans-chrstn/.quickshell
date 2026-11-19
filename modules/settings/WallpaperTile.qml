import QtQuick
import qs.components
import qs.core
import qs.components.media
import qs.services.wallpaper

HighlightableSurface {
    id: root

    required property var record
    readonly property string path: String(record?.path || "")
    readonly property string state: String(record?.state || "unknown")
    readonly property string kind: String(record?.kind || "unsupported")
    readonly property string rendererBackend: WallpaperRenderSupportService.rendererFor(record)
    readonly property bool animatedSupported: rendererBackend === "animated-image" || rendererBackend === "animated-media"
    readonly property bool selectable: state === "ready" && rendererBackend.length > 0
    signal activated

    interactive: false
    focused: hover.hovered
    accentColor: Theme.accent
    baseColor: Theme.fillSubtle
    cornerRadius: 12
    clip: true
    scale: tap.pressed && selectable ? 0.975 : 1

    Behavior on scale {
        NumberAnimation {
            duration: 90
            easing.type: Easing.OutCubic
        }
    }
    MediaThumbnail {
        id: preview
        anchors.fill: parent
        anchors.margins: root.selected ? 3 : 2
        record: root.record
        cornerRadius: Math.max(0, root.cornerRadius - anchors.margins)
    }

    Rectangle {
        anchors.fill: preview
        radius: Math.max(0, root.cornerRadius - preview.anchors.margins)
        color: Theme.scrim
        visible: !preview.previewReady || hover.hovered
        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 4
        visible: !preview.previewReady

        IslandGlyph {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 20
            height: 20
            name: root.state === "failed" || root.state === "unsupported" ? "close" : "more"
            glyphColor: Theme.textSecondary

            SequentialAnimation on opacity {
                running: !preview.previewReady && root.state !== "failed" && root.state !== "unsupported" && !Design.reducedMotion
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0.35
                    duration: Design.weatherPulseDuration
                }
                NumberAnimation {
                    to: 1
                    duration: Design.weatherPulseDuration
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.state === "failed" || root.state === "unsupported" || preview.poster.state === "failed"
            text: root.state === "unsupported" ? "Unsupported" : "Unavailable"
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeCaption
        }
    }

    IslandGlyph {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 7
        width: 16
        height: 16
        visible: root.kind === "video" && preview.previewReady
        name: "play"
        glyphColor: Theme.textPrimary
    }

    IslandGlyph {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        width: 18
        height: 18
        visible: root.selected
        name: "checkmark"
        glyphColor: Theme.textPrimary
    }

    HoverHandler {
        id: hover
    }
    TapHandler {
        id: tap
        enabled: root.selectable
        onTapped: root.activated()
    }
}
