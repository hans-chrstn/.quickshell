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
    property bool quiet: false

    radius: Design.editorSectionRadius
    color: quiet ? Theme.fillFaint : Theme.fillQuiet
    border.width: 1
    border.color: quiet ? Theme.separatorQuiet : Theme.separator

    ColumnLayout {
        width: parent.width - Design.space16 * 2
        x: Design.space16
        y: root.topAligned ? Design.space16 : (parent.height - height) / 2
        height: implicitHeight
        spacing: Design.space8

        Loader {
            Layout.fillWidth: true
            visible: active
            active: root.detailComponent !== null && root.topAligned
            sourceComponent: root.detailComponent
        }

        Text {
            Layout.fillWidth: true
            text: root.title
            visible: !root.detailTakesOver
            color: Theme.textPrimary
            font.family: Design.fontText
            font.pixelSize: Design.typeBody
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            visible: root.description.length > 0 && !root.detailTakesOver
            text: root.description
            color: Theme.textSecondary
            wrapMode: Text.Wrap
            font.family: Design.fontText
            font.pixelSize: Design.typeLabel
            lineHeight: 1.15
        }

        Text {
            Layout.fillWidth: true
            visible: root.details.length > 0 && !root.detailTakesOver
            text: root.details
            color: Theme.textSecondary
            wrapMode: Text.Wrap
            font.family: Design.fontMono
            font.pixelSize: Design.typeLabel
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
                    elide: Text.ElideRight
                    font.family: Design.fontText
                    font.pixelSize: Design.typeLabel
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
