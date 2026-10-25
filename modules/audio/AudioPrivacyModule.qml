import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services.audio

Item {
    id: root

    property QtObject context: null
    readonly property bool expanded: context?.expanded ?? false
    readonly property real transitionProgress: Math.max(0, Math.min(1, Number(context?.expansionProgress) || 0))
    readonly property var presentation: AudioPrivacyPresentationService.presentation
    readonly property var control: AudioService.privacyControl
    readonly property real collapsedImplicitWidth: Math.min(310, compactWidth)
    readonly property real collapsedImplicitHeight: 26
    readonly property real expandedCopyWidth: Math.min(300, Math.max(titleText.implicitWidth, detailText.implicitWidth))
    readonly property real expandedImplicitWidth: Math.min(440, Math.max(360, 38 + 12 + expandedCopyWidth + 12 + 32))
    readonly property real expandedImplicitHeight: 42
    readonly property real compactWidth: 24 + 8 + Math.min(196, titleText.implicitWidth) + 8 + 3 + 8 + microphoneLabel.implicitWidth

    function toggleMute() {
        if (!control.canControl || control.busy)
            return;
        AudioService.setPrivacyMuted(!control.muted);
    }

    RowLayout {
        id: contentRow

        anchors.centerIn: parent
        width: root.collapsedImplicitWidth + (root.expandedImplicitWidth - root.collapsedImplicitWidth) * root.transitionProgress
        height: root.collapsedImplicitHeight + (root.expandedImplicitHeight - root.collapsedImplicitHeight) * root.transitionProgress
        spacing: 8 + 4 * root.transitionProgress

        Rectangle {
            Layout.preferredWidth: 24 + 14 * root.transitionProgress
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            radius: 8 + 5 * root.transitionProgress
            color: Theme.tint(Theme.privacy)

            IslandGlyph {
                anchors.centerIn: parent
                implicitWidth: 16 + 4 * root.transitionProgress
                implicitHeight: implicitWidth
                name: root.control.muted ? "microphoneMuted" : "microphone"
                glyphColor: Theme.privacy
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2 * root.transitionProgress

            Text {
                id: titleText
                Layout.fillWidth: true
                text: root.presentation.title
                color: Theme.textPrimary
                font.family: Design.fontDisplay
                font.pixelSize: 11 + 2 * root.transitionProgress
                font.weight: Font.DemiBold
                maximumLineCount: 1
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }

            Text {
                id: detailText
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight * root.transitionProgress
                Layout.maximumHeight: Layout.preferredHeight
                opacity: root.transitionProgress
                text: root.control.scopeLabel + " · " + root.control.targetName
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 10
                maximumLineCount: 1
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: 3 * (1 - root.transitionProgress)
            Layout.preferredHeight: 3
            Layout.alignment: Qt.AlignVCenter
            radius: 1.5
            color: Theme.privacy
            opacity: 1 - root.transitionProgress
        }

        Text {
            id: microphoneLabel
            Layout.preferredWidth: implicitWidth * (1 - root.transitionProgress)
            Layout.maximumWidth: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            text: "Microphone"
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: 9
            font.weight: Font.Medium
            maximumLineCount: 1
            opacity: 1 - root.transitionProgress
            clip: true
        }

        Item {
            Layout.preferredWidth: 32 * root.transitionProgress
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            opacity: root.transitionProgress
            clip: true

            GlyphButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                glyph: root.control.muted ? "microphone" : "microphoneMuted"
                glyphSize: 17
                primary: root.control.muted
                accentColor: Theme.privacy
                focusOnActivate: false
                enabled: root.transitionProgress > 0.98 && root.control.canControl && !root.control.busy
                accessibleName: (root.control.muted ? "Unmute " : "Mute ") + root.control.targetName
                toolTip: accessibleName + " · Default input only"
                onActivated: root.toggleMute()
            }
        }
    }
}
