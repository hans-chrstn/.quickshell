import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services.wallpaper.projects

Item {
    id: root

    required property string markerId
    required property var actions
    required property string triggerType
    required property bool enabled
    required property int priority
    required property int cooldownMs
    property bool addingAction: false
    property bool showingActions: true
    readonly property var actionChoices: [
        {
            id: "set-wallpaper",
            label: "Set wallpaper",
            description: "Apply a wallpaper or project output",
            badge: "W"
        },
        {
            id: "play-media",
            label: "Play media",
            description: "Start or resume timeline media",
            badge: "P"
        },
        {
            id: "set-property",
            label: "Set property",
            description: "Update a project or system value",
            badge: "S"
        },
        {
            id: "show-notification",
            label: "Show notification",
            description: "Present a Dynamic Island notification",
            badge: "N"
        }
    ]

    function actionChoice(type) {
        return actionChoices.find(choice => choice.id === String(type || "")) || {
            label: "Unknown action",
            description: "This action type is not available",
            badge: "?"
        };
    }
    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 5

        SegmentedPageBar {
            Layout.fillWidth: true
            pages: [
                {
                    id: "info",
                    label: "Info"
                },
                {
                    id: "actions",
                    label: "Actions"
                }
            ]
            currentPage: root.showingActions ? "actions" : "info"
            onPageSelected: pageId => {
                root.addingAction = false;
                root.showingActions = pageId === "actions";
            }
        }

        ColumnLayout {
            visible: !root.showingActions
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: "Trigger: " + root.triggerType + " · " + (root.enabled ? "Enabled" : "Disabled")
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 9
            }
            Text {
                Layout.fillWidth: true
                text: "Priority " + root.priority + " · Cooldown " + root.cooldownMs + " ms"
                color: Design.textMuted
                font.family: Design.fontMono
                font.pixelSize: 8
            }
        }

        ColumnLayout {
            visible: root.showingActions && !root.addingAction
            Layout.fillWidth: true
            spacing: 5

            Repeater {
                model: root.actions

                EditorMarkerActionRow {
                    required property var modelData
                    Layout.fillWidth: true
                    markerId: root.markerId
                    action: modelData
                    descriptor: root.actionChoice(modelData.type)
                }
            }

            HighlightableSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                interactive: true
                baseColor: "transparent"
                cornerRadius: 10
                onSurfaceActivated: root.addingAction = true

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    IslandGlyph {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "plus"
                        glyphColor: Design.textMuted
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add action"
                        color: Design.textMuted
                        font.family: Design.fontText
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }
            }
        }

        EditorMarkerActionPicker {
            visible: root.showingActions && root.addingAction
            Layout.fillWidth: true
            choices: root.actionChoices
            onCanceled: root.addingAction = false
            onChoiceSelected: choice => {
                WallpaperTimelineService.addMarkerAction(root.markerId, choice.id);
                root.addingAction = false;
            }
        }
    }
}
