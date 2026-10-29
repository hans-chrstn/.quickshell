import QtQuick

Item {
    id: root

    property bool constrained: false

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: "#05000000"
        border.width: 1
        border.color: "#10ffffff"
    }

    VisualLabWorkspaceToolbar {
        id: toolbar

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: root.constrained ? 44 : 48
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: toolbar.bottom
        }
        height: 1
        color: "#14ffffff"
    }

    VisualLabWorkspaceLibrary {
        id: library

        anchors {
            left: parent.left
            top: toolbar.bottom
            bottom: parent.bottom
        }
        width: 172
    }

    Rectangle {
        anchors {
            left: library.right
            top: toolbar.bottom
            bottom: parent.bottom
        }
        width: 1
        color: "#12ffffff"
    }

    VisualLabWorkspaceInspector {
        id: inspector

        anchors {
            right: parent.right
            top: toolbar.bottom
            bottom: parent.bottom
        }
        width: 190
    }

    Rectangle {
        anchors {
            right: inspector.left
            top: toolbar.bottom
            bottom: parent.bottom
        }
        width: 1
        color: "#12ffffff"
    }

    VisualLabWorkspaceTimeline {
        id: timeline

        anchors {
            left: library.right
            right: inspector.left
            bottom: parent.bottom
        }
        height: root.constrained ? 104 : 124
        constrained: root.constrained
    }

    Rectangle {
        anchors {
            left: library.right
            right: inspector.left
            bottom: timeline.top
        }
        height: 1
        color: "#12ffffff"
    }

    VisualLabWorkspacePreview {
        anchors {
            left: library.right
            right: inspector.left
            top: toolbar.bottom
            bottom: timeline.top
        }
    }
}
