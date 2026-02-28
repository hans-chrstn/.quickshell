import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.ui.shared

PanelWindow {
    id: root
    
    visible: false
    color: "transparent"
    
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    exclusionMode: visible ? ExclusionMode.Normal : ExclusionMode.Ignore
    focusable: visible
    WlrLayershell.keyboardFocus: (visible || saveAsOverlay.visible) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool isPreviewMode: false
    property bool entryStarted: false
    property bool isSaveAsActive: false
    property bool isExplorerExpanded: true
    property string pendingDeletePath: ""

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(() => {
                entryStarted = true
            })
            FileBrowserManager.filterMode = "notes"
            FileBrowserManager.navigateToPath(NotesManager.defaultNotesDir)
            FileBrowserManager.refresh()
        } else {
            entryStarted = false
            isSaveAsActive = false
            NotesManager.saveNotes()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ThemeManager.shadowPrimaryColor
        opacity: root.entryStarted ? 0.75 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        MouseArea { 
            anchors.fill: parent
            onClicked: {
                ViewManager.closeWindowByType("notes")
            }
        }
    }

    ClippingRectangle {
        id: windowFrame
        width: 1000
        height: 750
        anchors.centerIn: parent
        radius: 40
        color: ThemeManager.backgroundPrimaryColor
        border.color: ThemeManager.outlinePrimaryColor
        border.width: 1
        
        opacity: root.entryStarted ? 1.0 : 0
        scale: root.entryStarted ? 1.0 : 0.98
        
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                mouse.accepted = true
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: explorerSidebar
                Layout.preferredWidth: root.isExplorerExpanded ? 280 : 0
                Layout.fillHeight: true
                color: ThemeManager.surfaceSubtleColor
                clip: true
                
                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutQuart
                    }
                }

                Item {
                    width: 280
                    height: explorerSidebar.height
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 32
                        anchors.topMargin: 20
                        anchors.bottomMargin: 20
                        spacing: 20

                        RowLayout {
                            Layout.fillWidth: true
                            StyledLabel {
                                text: "EXPLORER"
                                type: "caption"
                                customColor: ThemeManager.surfaceContentColor
                                font.weight: Font.Black
                                letterSpacing: 2
                                opacity: 0.5
                                Layout.fillWidth: true 
                            }
                            BaseButton {
                                width: 24
                                height: 24
                                onClicked: {
                                    FileBrowserManager.navigateToParent()
                                }
                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: "󰁝"
                                    type: "icon"
                                    font.pixelSize: 14
                                    customColor: ThemeManager.accentColor
                                }
                            }
                        }

                        ListView {
                            id: fileList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: FileBrowserManager.fileModel
                            clip: false
                            spacing: 6
                            
                            delegate: BaseButton {
                                id: fileDelegate
                                width: ListView.view ? ListView.view.width : 230
                                height: 38
                                onClicked: {
                                    if (model.isDir) {
                                        FileBrowserManager.navigateToPath(model.path)
                                    } else {
                                        NotesManager.openFile(model.path)
                                    }
                                }
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    color: NotesManager.currentFilePath === model.path ? ThemeManager.accentColor : (fileDelegate.isHovered ? ThemeManager.surfaceStrongColor : ThemeManager.surfacePrimaryColor)
                                    border.color: (fileDelegate.isHovered || NotesManager.currentFilePath === model.path) ? ThemeManager.accentColor : ThemeManager.outlineVariantColor
                                    border.width: 1
                                }
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10
                                    StyledLabel { 
                                        text: model.isDir ? "󰉋" : "󰠮"
                                        type: "icon"
                                        font.pixelSize: 14
                                        customColor: (NotesManager.currentFilePath === model.path) ? ThemeManager.contentPrimaryColor : (model.isDir ? ThemeManager.accentColor : ThemeManager.surfaceContentColor)
                                    }
                                    StyledLabel { 
                                        text: model.name
                                        type: "body"
                                        Layout.fillWidth: true
                                        elideMode: Text.ElideRight
                                        font.weight: NotesManager.currentFilePath === model.path ? Font.Bold : Font.Normal
                                        customColor: (NotesManager.currentFilePath === model.path) ? ThemeManager.contentPrimaryColor : ThemeManager.surfaceContentColor
                                    }
                                    BaseButton {
                                        width: 20
                                        height: 20
                                        visible: fileDelegate.isHovered && !model.isDir && model.name !== ".."
                                        onClicked: {
                                            root.pendingDeletePath = model.path
                                        }
                                        StyledLabel { 
                                            anchors.centerIn: parent
                                            text: "󰆴"
                                            type: "icon"
                                            font.pixelSize: 14
                                            customColor: ThemeManager.dangerColor 
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            StyledLabel {
                                text: "RECENT NOTES"
                                type: "caption"
                                customColor: ThemeManager.surfaceContentColor
                                font.weight: Font.Black
                                letterSpacing: 2
                                opacity: 0.5
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: ThemeManager.surfaceContentColor
                                opacity: 0.1
                            }
                        }
                        
                        ListView {
                            id: recentList
                            Layout.preferredHeight: 180
                            Layout.fillWidth: true
                            model: NotesManager.recentFiles
                            clip: false
                            spacing: 4
                            delegate: BaseButton {
                                id: recDel
                                width: ListView.view ? ListView.view.width : 230
                                height: 34
                                onClicked: {
                                    NotesManager.openFile(modelData)
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: NotesManager.currentFilePath === modelData ? ThemeManager.accentColor : (recDel.isHovered ? ThemeManager.surfaceStrongColor : ThemeManager.surfaceSubtleColor)
                                    border.color: (recDel.isHovered || NotesManager.currentFilePath === modelData) ? ThemeManager.accentColor : "transparent"
                                    border.width: 1
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 8
                                    StyledLabel { 
                                        text: modelData.split('/').pop()
                                        type: "caption"
                                        customColor: NotesManager.currentFilePath === modelData ? ThemeManager.contentPrimaryColor : ThemeManager.surfaceContentColor
                                        font.weight: (NotesManager.currentFilePath === modelData || recDel.isHovered) ? Font.DemiBold : Font.Normal
                                        Layout.fillWidth: true
                                        elideMode: Text.ElideRight
                                    }
                                    BaseButton {
                                        width: 20
                                        height: 20
                                        visible: recDel.isHovered || NotesManager.currentFilePath === modelData
                                        onClicked: {
                                            NotesManager.deleteRecent(modelData)
                                        }
                                        StyledLabel { 
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            type: "icon"
                                            font.pixelSize: 12
                                            customColor: NotesManager.currentFilePath === modelData ? ThemeManager.contentPrimaryColor : ThemeManager.dangerColor
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: 1
                Layout.fillHeight: true
                color: ThemeManager.surfaceContentColor
                opacity: 0.05
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 32
                        anchors.rightMargin: 32
                        spacing: 20
                        BaseButton {
                            width: 32
                            height: 32
                            onClicked: {
                                root.isExplorerExpanded = !root.isExplorerExpanded
                            }
                            StyledLabel {
                                anchors.centerIn: parent
                                text: root.isExplorerExpanded ? "󰍜" : "󰍟"
                                type: "icon"
                                customColor: ThemeManager.accentColor
                            }
                        }
                        BaseButton {
                            id: titleBtn
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            onClicked: {
                                root.isSaveAsActive = true
                            }
                            ColumnLayout {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                StyledLabel { 
                                    text: NotesManager.currentFilePath ? NotesManager.currentFilePath.split('/').pop() : "NEW DOCUMENT"
                                    type: "title"
                                    font.weight: Font.Black
                                    customColor: titleBtn.isHovered ? ThemeManager.accentColor : ThemeManager.surfaceContentColor 
                                }
                                StyledLabel {
                                    text: NotesManager.hasUnsavedChanges ? "UNSAVED CHANGES" : "AUTOSAVED"
                                    type: "caption"
                                    font.weight: Font.Black
                                    customColor: NotesManager.hasUnsavedChanges ? ThemeManager.dangerColor : ThemeManager.accentColor
                                    letterSpacing: 1 
                                }
                            }
                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Row {
                            spacing: 12
                            BaseButton {
                                width: 40
                                height: 40
                                onClicked: {
                                    NotesManager.createNewNote()
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 20
                                    color: parent.isHovered ? ThemeManager.surfacePrimaryColor : "transparent"
                                    StyledLabel {
                                        anchors.centerIn: parent
                                        text: "󰐕"
                                        type: "icon"
                                        customColor: ThemeManager.surfaceContentColor
                                    }
                                }
                            }
                            BaseButton {
                                width: 40
                                height: 40
                                onClicked: {
                                    root.isSaveAsActive = true
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 20
                                    color: parent.isHovered ? ThemeManager.surfacePrimaryColor : "transparent"
                                    StyledLabel {
                                        anchors.centerIn: parent
                                        text: "󰆓"
                                        type: "icon"
                                        customColor: ThemeManager.surfaceContentColor
                                    }
                                }
                            }
                            Rectangle {
                                width: 140
                                height: 32
                                radius: 16
                                color: ThemeManager.surfacePrimaryColor
                                Layout.alignment: Qt.AlignVCenter
                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    Repeater {
                                        model: ["EDIT", "VIEW"]
                                        delegate: BaseButton {
                                            width: 68
                                            height: 28
                                            onClicked: {
                                                root.isPreviewMode = (modelData === "VIEW")
                                            }
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 14
                                                color: (root.isPreviewMode === (modelData === "VIEW")) ? ThemeManager.accentColor : "transparent"
                                                StyledLabel {
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    type: "caption"
                                                    font.weight: Font.Black
                                                    customColor: (root.isPreviewMode === (modelData === "VIEW")) ? ThemeManager.contentPrimaryColor : ThemeManager.surfaceContentColor
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        BaseButton {
                            width: 36
                            height: 36
                            onClicked: {
                                ViewManager.closeWindowByType("notes")
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 18
                                color: ThemeManager.surfacePrimaryColor
                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    type: "icon"
                                    customColor: ThemeManager.surfaceContentColor
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: ThemeManager.surfaceContentColor
                    opacity: 0.05
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ScrollView {
                        id: notesScroll
                        anchors.fill: parent
                        clip: true
                        background: null
                        
                        Loader {
                            id: contentLoader
                            width: notesScroll ? notesScroll.availableWidth : 0
                            sourceComponent: root.isPreviewMode ? previewComp : editorComp
                        }

                        Component {
                            id: editorComp
                            TextArea {
                                width: notesScroll ? notesScroll.availableWidth : 0
                                text: NotesManager.content
                                wrapMode: TextEdit.Wrap
                                color: ThemeManager.surfaceContentColor
                                font.family: ThemeManager.fontFamily
                                font.pixelSize: 16
                                topPadding: 40
                                leftPadding: 40
                                rightPadding: 40
                                bottomPadding: 40
                                onTextEdited: {
                                    NotesManager.content = text
                                }
                                selectionColor: ThemeManager.accentColor
                                selectedTextColor: ThemeManager.contentPrimaryColor
                                background: null
                                Component.onCompleted: {
                                    forceActiveFocus()
                                }
                            }
                        }
                        Component {
                            id: previewComp
                            Text {
                                width: notesScroll ? notesScroll.availableWidth : 0
                                padding: 40
                                text: NotesManager.content
                                textFormat: Text.MarkdownText
                                wrapMode: Text.Wrap
                                color: ThemeManager.surfaceContentColor
                                font.family: ThemeManager.fontFamily
                                font.pixelSize: 16
                                linkColor: ThemeManager.accentColor
                                onLinkActivated: (link) => {
                                    Quickshell.execDetached(["xdg-open", link])
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: saveAsOverlay
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.85)
            visible: root.isSaveAsActive
            z: 100
            opacity: visible ? 1.0 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.isSaveAsActive = false
                }
            }
            Rectangle {
                width: 450
                height: 220
                anchors.centerIn: parent
                radius: 32
                color: ThemeManager.backgroundPrimaryColor
                border.color: ThemeManager.outlineStrongColor
                border.width: 1
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 32
                    spacing: 20
                    StyledLabel {
                        text: "SAVE NOTE AS"
                        type: "sidebarHeader"
                        customColor: ThemeManager.accentColor
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 12
                        color: ThemeManager.surfaceStrongColor
                        border.color: ThemeManager.accentColor
                        border.width: 1
                        TextInput {
                            id: saveAsInput
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            color: ThemeManager.surfaceContentColor
                            font.family: ThemeManager.fontFamily
                            font.pixelSize: 15
                            focus: saveAsOverlay.visible
                            text: NotesManager.currentFilePath ? NotesManager.currentFilePath.split('/').pop() : "note.md"
                            onAccepted: {
                                NotesManager.saveAs(FileBrowserManager.currentPath + "/" + text)
                                root.isSaveAsActive = false
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Item {
                            Layout.fillWidth: true
                        }
                        BaseButton {
                            width: 100
                            height: 36
                            onClicked: {
                                root.isSaveAsActive = false
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: ThemeManager.surfacePrimaryColor
                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: "CANCEL"
                                    type: "caption"
                                    customColor: ThemeManager.surfaceContentColor
                                }
                            }
                        }
                        BaseButton {
                            width: 100
                            height: 36
                            onClicked: {
                                saveAsInput.accepted()
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: ThemeManager.accentColor
                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: "SAVE"
                                    type: "caption"
                                    customColor: ThemeManager.contentPrimaryColor
                                    font.weight: Font.Black
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: deleteOverlay
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.85)
            visible: root.pendingDeletePath !== ""
            z: 110
            opacity: visible ? 1.0 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.pendingDeletePath = ""
                }
            }
            Rectangle {
                width: 450
                height: 200
                anchors.centerIn: parent
                radius: 32
                color: ThemeManager.backgroundPrimaryColor
                border.color: ThemeManager.dangerColor
                border.width: 1
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 32
                    spacing: 20
                    StyledLabel {
                        text: "DELETE FILE?"
                        type: "sidebarHeader"
                        customColor: ThemeManager.dangerColor
                    }
                    StyledLabel { 
                        text: "Are you sure you want to permanently delete\n" + root.pendingDeletePath.split('/').pop() + "?"
                        type: "body"
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Item {
                            Layout.fillWidth: true
                        }
                        BaseButton {
                            width: 100
                            height: 36
                            onClicked: {
                                root.pendingDeletePath = ""
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: ThemeManager.surfacePrimaryColor
                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: "CANCEL"
                                    type: "caption"
                                }
                            }
                        }
                        BaseButton {
                            width: 100
                            height: 36
                            onClicked: {
                                NotesManager.deleteFile(root.pendingDeletePath)
                                root.pendingDeletePath = ""
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: ThemeManager.dangerColor
                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: "DELETE"
                                    type: "caption"
                                    customColor: ThemeManager.contentOnBackgroundColor
                                    font.weight: Font.Black
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+S"
        onActivated: {
            NotesManager.saveNotes()
        }
    }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (isSaveAsActive) {
                isSaveAsActive = false
            } else if (pendingDeletePath !== "") {
                pendingDeletePath = ""
            } else {
                ViewManager.closeWindowByType("notes")
            }
        }
    }
}
