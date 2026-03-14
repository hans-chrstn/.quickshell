import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

StyledCard {
    id: root

    property var newsData: null
    
    width: parent ? parent.width : 0
    implicitHeight: {
        return contentColumn.implicitHeight + 30
    }
    backgroundColor: Qt.rgba(1, 1, 1, 0.02)

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        StyledLabel {
            text: {
                if (!root.newsData) {
                    return ""
                }
                return String(root.newsData.title || "")
            }
            type: "body"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        StyledLabel {
            text: {
                if (!root.newsData) {
                    return ""
                }
                return String(root.newsData.description || "")
            }
            type: "caption"
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            visible: {
                return text !== ""
            }
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 15

            StyledLabel {
                text: {
                    if (!root.newsData) {
                        return ""
                    }
                    let d = root.newsData.date
                    if (!d) return ""
                    return String(d).split(" ").slice(0, 4).join(" ")
                }
                type: "caption"
                font.pixelSize: 9
                opacity: 0.4
                Layout.fillWidth: true
            }

            BaseButton {
                width: 80
                height: 24
                cornerRadius: 6
                
                onClicked: {
                    if (root.newsData && root.newsData.link) {
                        Quickshell.execDetached([
                            "xdg-open", 
                            root.newsData.link
                        ])
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: ThemeManager.accentColor
                    opacity: 0.15
                }

                StyledLabel {
                    anchors.centerIn: parent
                    text: "Read More"
                    type: "caption"
                    font.pixelSize: 9
                    color: ThemeManager.accentColor
                }
            }
        }
    }
}
