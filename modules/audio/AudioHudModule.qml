import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services.audio
import "../../services/audio/AudioPresentationModel.js" as AudioPresentationModel

Item {
    id: root

    property QtObject context: null
    readonly property var change: AudioHudService.current
    readonly property bool muted: change?.muted ?? false
    readonly property bool inputRole: change?.role === "input"
    readonly property bool amplified: !muted && (Number(change?.volume) || 0) > 1.0001
    readonly property color accent: muted ? Theme.textSecondary : amplified ? Theme.warning : inputRole ? Theme.success : Theme.textPrimary
    readonly property real displayMaximum: Math.max(1, Number(change?.volume) || 0)
    readonly property real collapsedImplicitWidth: contentRow.implicitWidth
    readonly property real collapsedImplicitHeight: 24
    readonly property real expandedImplicitWidth: collapsedImplicitWidth
    readonly property real expandedImplicitHeight: collapsedImplicitHeight

    RowLayout {
        id: contentRow

        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            radius: 8
            color: root.muted ? Theme.tintSubtle(root.accent) : Theme.tint(root.accent)

            IslandGlyph {
                anchors.centerIn: parent
                implicitWidth: 17
                implicitHeight: 17
                name: AudioPresentationModel.iconName(root.change)
                glyphColor: root.accent
            }
        }

        LevelTrack {
            Layout.preferredWidth: 112
            Layout.alignment: Qt.AlignVCenter
            value: root.muted ? 0 : Number(root.change?.volume) || 0
            maximumValue: root.displayMaximum
            accentColor: root.accent
        }

        Text {
            Layout.preferredWidth: 42
            Layout.alignment: Qt.AlignVCenter
            text: AudioPresentationModel.valueText(root.change)
            color: root.muted ? Theme.textSecondary : Theme.textPrimary
            font.family: Design.fontMono
            font.pixelSize: 10
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignRight
            maximumLineCount: 1
        }
    }
}
