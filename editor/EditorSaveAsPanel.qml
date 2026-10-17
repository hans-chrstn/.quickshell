import QtQuick
import QtQuick.Layouts
import qs.components.filepicker
import qs.components.input
import qs.core
import qs.services.wallpaper.projects

Rectangle {
    id: root

    color: Theme.islandExpanded
    radius: Design.editorSectionRadius
    border.width: 1
    border.color: Theme.glassStroke

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
                    text: WallpaperEditorService.saveAsChoosingParent ? "Choose Parent Folder" : "Save Project As"
                    color: Theme.textPrimary
                    font.family: Design.fontDisplay
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: WallpaperEditorService.saveAsChoosingParent ? "The project folder will be created inside this location." : "Choose a parent and a separate folder name."
                    color: Theme.textSecondary
                    font.family: Design.fontText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            PickerButton {
                label: "Cancel"
                enabled: !WallpaperEditorService.savePreflightBusy
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

            Item {
                Layout.fillHeight: true
            }

            Text {
                Layout.fillWidth: true
                text: "Parent folder"
                color: Theme.textSecondary
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
                    color: Theme.fillElevated
                    border.width: 1
                    border.color: Theme.separator

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        text: WallpaperEditorService.saveParentPath
                        color: Theme.textPrimary
                        font.family: Design.fontMono
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                    }
                }

                PickerButton {
                    label: "Choose…"
                    enabled: !WallpaperEditorService.savePreflightBusy
                    onActivated: WallpaperEditorService.beginChoosingSaveParent()
                }
            }

            DecoratedTextField {
                Layout.fillWidth: true
                label: "Project folder name"
                placeholderText: "My Wallpaper Project"
                maximumLength: 128
                enabled: !WallpaperEditorService.savePreflightBusy
                text: WallpaperEditorService.saveFolderName
                invalid: WallpaperEditorService.saveAsOpened && !WallpaperEditorService.saveFolderNameValid
                supportingText: invalid ? "Use a visible folder name without path separators." : ""
                onTextChanged: WallpaperEditorService.setSaveFolderName(text)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                radius: 13
                color: Theme.tintSubtle(Theme.accent)
                border.width: 1
                border.color: WallpaperEditorService.savePreview.accepted ? Theme.tintBorder(Theme.accent) : Theme.separator

                Column {
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 4

                    Text {
                        width: parent.width
                        text: "Final project location"
                        color: Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: 9
                    }
                    Text {
                        width: parent.width
                        text: WallpaperEditorService.savePreview.accepted ? WallpaperEditorService.savePreview.plan.destinationPath : "Choose a valid destination"
                        color: WallpaperEditorService.savePreview.accepted ? Theme.textPrimary : Theme.textSecondary
                        font.family: Design.fontMono
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: WallpaperEditorService.savePreflightState === "saved" || WallpaperEditorService.savePreflightState === "published-with-warning" || WallpaperEditorService.savePreflightState === "failed"
                text: WallpaperEditorService.savePreflightState === "saved" ? "Project saved successfully." : WallpaperEditorService.savePreflightState === "published-with-warning" ? WallpaperEditorService.savePreflightError : WallpaperEditorService.savePreflightError
                color: WallpaperEditorService.savePreflightState === "saved" ? Theme.success : Theme.danger
                font.family: Design.fontText
                font.pixelSize: 10
                wrapMode: Text.Wrap
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }
                PickerButton {
                    label: WallpaperEditorService.savePreflightBusy ? "Saving " + Math.round(WallpaperDraftPublicationService.progress * 100) + "%" : WallpaperEditorService.savePreflightState === "saved" ? "Saved" : "Save Project"
                    primary: true
                    enabled: !WallpaperEditorService.savePreflightBusy
                    onActivated: WallpaperEditorService.finishSaveAsReview()
                }
            }
        }
    }
}
