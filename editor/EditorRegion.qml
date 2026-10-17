import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    property string title: ""
    property string description: ""
    property string details: ""
    property var detailItems: []
    property Component detailComponent: null
    property bool detailTakesOver: false
    property bool topAligned: false
    property string glyph: ""
    property bool quiet: false

    radius: Design.editorSectionRadius
    color: quiet ? Theme.fillFaint : Theme.fillQuiet
    border.width: 1
    border.color: quiet ? Theme.separatorQuiet : Theme.separator

    ColumnLayout {
        width: root.topAligned ? parent.width - 28 : Math.min(parent.width - 28, 280)
        x: root.topAligned ? 14 : (parent.width - width) / 2
        y: root.topAligned ? 14 : (parent.height - height) / 2
        height: implicitHeight
        spacing: 8

        Loader {
            Layout.fillWidth: true
            visible: active
            active: root.detailComponent !== null && root.topAligned
            sourceComponent: root.detailComponent
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            visible: root.glyph.length > 0 && !root.detailTakesOver
            implicitWidth: 32
            implicitHeight: 32
            radius: 10
            color: Theme.fillSubtle

            Text {
                anchors.centerIn: parent
                text: root.glyph
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.title
            visible: !root.detailTakesOver
            color: Theme.textPrimary
            horizontalAlignment: Text.AlignHCenter
            font.family: Design.fontText
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            visible: root.description.length > 0 && !root.detailTakesOver
            text: root.description
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.family: Design.fontText
            font.pixelSize: 11
            lineHeight: 1.15
        }

        Text {
            Layout.fillWidth: true
            visible: root.details.length > 0 && !root.detailTakesOver
            text: root.details
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.family: Design.fontMono
            font.pixelSize: 9
            opacity: 0.82
        }

        ColumnLayout {
            visible: !root.detailTakesOver
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: root.detailItems

                Text {
                    required property string modelData
                    Layout.fillWidth: true
                    text: modelData
                    color: Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.family: Design.fontText
                    font.pixelSize: 9
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            visible: active && !root.topAligned
            active: root.detailComponent !== null && !root.topAligned
            sourceComponent: root.detailComponent
        }
    }
}
