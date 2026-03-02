import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

BaseButton {
    id: root
    
    property var modelData
    
    width: ListView.view ? ListView.view.width : 230
    height: 34
    
    onClicked: {
        NotesManager.openFile(modelData)
    }
    
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: NotesManager.currentFilePath === modelData ? ThemeManager.accentColor : (root.isHovered ? ThemeManager.surfaceStrongColor : ThemeManager.surfaceSubtleColor)
        border.color: (root.isHovered || NotesManager.currentFilePath === modelData) ? ThemeManager.accentColor : "transparent"
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
            font.weight: (NotesManager.currentFilePath === modelData || root.isHovered) ? Font.DemiBold : Font.Normal
            Layout.fillWidth: true
            elideMode: Text.ElideRight
        }
        
        BaseButton {
            width: 20
            height: 20
            visible: root.isHovered || NotesManager.currentFilePath === modelData
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
