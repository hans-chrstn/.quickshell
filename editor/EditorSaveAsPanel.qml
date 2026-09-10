import QtQuick
import QtQuick.Layouts
import qs.components.filepicker
import qs.components.input
import qs.core
import qs.services.wallpaper.projects

Rectangle {
    id: root

    color: Design.islandExpanded
    radius: Design.editorSectionRadius
    border.width: 1
    border.color: Design.glassStroke

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: WallpaperEditorService.saveAsChoosingParent
                        ? "Choose Parent Folder" : "Save Project As"
                    color: Design.text
                    font.family: Design.fontDisplay
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: WallpaperEditorService.saveAsChoosingParent
                        ? "The project folder will be created inside this location."
                        : "Choose a parent and a separate folder name."
                    color: Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            PickerButton {
                label: "Cancel"
                onActivated: WallpaperEditorService.closeSaveAs()
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: WallpaperEditorService.saveAsChoosingParent
            source: Qt.resolvedUrl("EditorSaveParentPicker.qml")
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !WallpaperEditorService.saveAsChoosingParent
            spacing: 14

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: "Parent folder"
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 10
                font.weight: Font.Medium
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 11
                    color: Design.surfaceRaised
                    border.width: 1
                    border.color: Design.separator

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        text: WallpaperEditorService.saveParentPath
                        color: Design.text
                        font.family: Design.fontMono
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                    }
                }

                PickerButton {
                    label: "Choose…"
                    onActivated: WallpaperEditorService.beginChoosingSaveParent()
                }
            }

            DecoratedTextField {
                Layout.fillWidth: true
                label: "Project folder name"
                placeholderText: "My Wallpaper Project"
                maximumLength: 128
                text: WallpaperEditorService.saveFolderName
                invalid: WallpaperEditorService.saveAsOpened
                    && !WallpaperEditorService.saveFolderNameValid
                supportingText: invalid ? "Use a visible folder name without path separators." : ""
                onTextChanged: WallpaperEditorService.setSaveFolderName(text)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                radius: 13
                color: Qt.rgba(Design.blue.r, Design.blue.g,
                    Design.blue.b, 0.10)
                border.width: 1
                border.color: WallpaperEditorService.savePreview.accepted
                    ? Qt.rgba(Design.blue.r, Design.blue.g,
                        Design.blue.b, 0.42) : Design.separator

                Column {
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 4

                    Text {
                        width: parent.width
                        text: "Final project location"
                        color: Design.textMuted
                        font.family: Design.fontText
                        font.pixelSize: 9
                    }
                    Text {
                        width: parent.width
                        text: WallpaperEditorService.savePreview.accepted
                            ? WallpaperEditorService.savePreview.plan.destinationPath
                            : "Choose a valid destination"
                        color: WallpaperEditorService.savePreview.accepted
                            ? Design.text : Design.textMuted
                        font.family: Design.fontMono
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }
                PickerButton {
                    label: "Done"
                    primary: true
                    onActivated: WallpaperEditorService.finishSaveAsReview()
                }
            }
        }
    }
}
