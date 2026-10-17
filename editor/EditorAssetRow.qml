import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.editor

HighlightableSurface {
    id: root

    required property var asset
    required property string workspaceId
    readonly property bool dragAvailable: asset.state === "available"
    readonly property int sourceDurationMs: asset.declaredKind === "static" ? 0 : Math.max(0, Math.round(Number(asset.media?.durationMs) || 0))
    signal activated
    signal contextRequested(real localX, real localY)

    readonly property string extension: {
        const path = asset.resolvedPath || asset.sourcePath || "";
        const name = path.slice(path.lastIndexOf("/") + 1);
        const dot = name.lastIndexOf(".");
        return dot >= 0 ? name.slice(dot + 1).toUpperCase() : "MEDIA";
    }
    readonly property color stateColor: asset.state === "available" ? Theme.success : asset.state === "pending" ? Theme.warning : Theme.danger

    implicitHeight: 58
    interactive: false
    focused: hover.hovered
    accentColor: Theme.accent
    baseColor: "transparent"
    cornerRadius: 13

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 9
        spacing: 9

        Rectangle {
            implicitWidth: 40
            implicitHeight: 40
            radius: 11
            color: Theme.fillSubtle

            EditorAssetThumbnail {
                id: thumbnail
                anchors.fill: parent
                anchors.margins: 1
                asset: root.asset
                workspaceId: root.workspaceId
                cornerRadius: parent.radius - 1
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - 6
                text: root.extension
                color: Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.family: Design.fontText
                font.pixelSize: 8
                font.weight: Font.DemiBold
                visible: !thumbnail.previewReady
            }

            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 3
                width: 6
                height: 6
                radius: 3
                color: root.stateColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.asset.name
                color: Theme.textPrimary
                elide: Text.ElideRight
                font.family: Design.fontText
                font.pixelSize: 11
                font.weight: Font.Medium
            }
            Text {
                Layout.fillWidth: true
                text: root.asset.state === "available" ? root.asset.declaredKind.replace("-", " ") : root.asset.state
                color: Theme.textSecondary
                elide: Text.ElideRight
                font.family: Design.fontText
                font.pixelSize: 9
                font.capitalization: Font.Capitalize
            }
        }
    }

    HoverHandler {
        id: hover
    }

    Item {
        id: dragTransport

        width: 1
        height: 1
        z: 20

        Drag.dragType: Drag.None
        Drag.source: root
        Drag.keys: ["wallpaper-editor-media"]
        Drag.supportedActions: Qt.CopyAction
        Drag.proposedAction: Qt.CopyAction
        Drag.hotSpot.x: 0
        Drag.hotSpot.y: 0
    }

    DragHandler {
        id: assetDrag
        target: dragTransport
        enabled: root.dragAvailable
        acceptedButtons: Qt.LeftButton
        dragThreshold: 7
        onActiveChanged: {
            if (active) {
                root.activated();
                dragTransport.Drag.start(Qt.CopyAction);
            } else {
                dragTransport.Drag.drop();
                dragTransport.x = 0;
                dragTransport.y = 0;
            }
        }
    }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.activated()
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: eventPoint => {
            root.activated();
            root.contextRequested(eventPoint.position.x, eventPoint.position.y);
        }
    }
}
