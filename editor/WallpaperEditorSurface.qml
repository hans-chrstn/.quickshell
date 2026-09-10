import QtQuick
import QtQuick.Layouts
import qs.components.filepicker
import qs.core
import qs.editor
import qs.services.wallpaper.projects

Rectangle {
    id: root

    focus: true
    Component.onCompleted: forceActiveFocus()

    readonly property bool compact: width < 980
    readonly property int sideWidth: compact
        ? Math.max(156, Math.round(width * 0.20))
        : Math.max(210, Math.min(280, Math.round(width * 0.19)))
    readonly property int inspectorWidth: compact
        ? Math.max(180, Math.round(width * 0.23))
        : Math.max(240, Math.min(320, Math.round(width * 0.22)))

    radius: Design.editorPanelRadius
    color: Design.islandExpanded
    border.width: 1
    border.color: Design.glassStroke
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: Design.editorGap

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            Layout.leftMargin: 8
            Layout.rightMargin: 2
            spacing: 9

            Rectangle {
                implicitWidth: 25
                implicitHeight: 25
                radius: 8
                color: Qt.rgba(Design.blue.r, Design.blue.g, Design.blue.b, 0.18)

                Text {
                    anchors.centerIn: parent
                    text: "W"
                    color: Design.blue
                    font.family: Design.fontDisplay
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: WallpaperEditorService.projectName
                    color: Design.text
                    font.family: Design.fontDisplay
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: "Wallpaper Studio"
                    color: Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                implicitWidth: statusText.implicitWidth + 18
                implicitHeight: 25
                radius: 9
                color: Qt.rgba(1, 1, 1, 0.045)
                Text {
                    id: statusText
                    anchors.centerIn: parent
                    text: "Foundation"
                    color: Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }

            PickerButton {
                label: "Save As"
                enabled: WallpaperEditorService.workspaceId.length > 0
                    && !WallpaperEditorService.importBusy
                onActivated: WallpaperEditorService.openSaveAs()
            }

            EditorIconButton {
                accessibleName: "Close editor"
                onClicked: WallpaperEditorService.close()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 220
            spacing: Design.editorGap

            EditorMediaLibrary {
                Layout.preferredWidth: root.sideWidth
                Layout.fillHeight: true
            }

            EditorRegion {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Preview"
                description: "The shared wallpaper renderer will preview the selected project here."
                glyph: "▶"
                quiet: true
            }

            EditorRegion {
                Layout.preferredWidth: root.inspectorWidth
                Layout.fillHeight: true
                title: WallpaperEditorService.selectedAsset
                    ? WallpaperEditorService.selectedAsset.name : "Inspector"
                description: WallpaperEditorService.selectedAsset
                    ? (WallpaperEditorService.selectedAsset.state === "available"
                        ? WallpaperEditorService.selectedAsset.declaredKind
                        : WallpaperEditorService.selectedAsset.state)
                    : "Select an asset or timeline item to edit its properties."
                glyph: "···"
            }
        }

        EditorRegion {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(170,
                Math.min(270, Math.round(root.height * 0.29)))
            title: "Timeline"
            description: "Tracks, clips, and trigger markers arrive in focused editing slices."
            glyph: "—"
            quiet: true
        }
    }

    Loader {
        anchors.fill: parent
        anchors.margins: 10
        z: 50
        active: WallpaperEditorService.pickerOpened
        source: Qt.resolvedUrl("EditorMediaPicker.qml")
    }

    Loader {
        anchors.fill: parent
        anchors.margins: 10
        z: 51
        active: WallpaperEditorService.saveAsOpened
        source: Qt.resolvedUrl("EditorSaveAsPanel.qml")
    }
}
