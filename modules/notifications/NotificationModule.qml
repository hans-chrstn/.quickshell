import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.notifications

Item {
    id: root

    property QtObject context: null
    property string registeredPresentationScreen: ""
    readonly property bool expanded: context?.expanded ?? false
    readonly property var notice: NotificationService.current
    readonly property color accent: notice?.severity === "error" ? Design.red
        : notice?.severity === "warning" ? Design.yellow
        : notice?.severity === "success" ? Design.green : Design.blue
    readonly property bool hasSource: String(notice?.source || "").length > 0
    readonly property bool hasBody: String(notice?.message || "").length > 0
    readonly property bool hasCount: Number(notice?.occurrenceCount) > 1

    readonly property real collapsedImplicitWidth: 20 + 7
        + Math.min(232, titleText.implicitWidth)
        + (hasCount ? 6 + countText.implicitWidth : 0)
    readonly property real collapsedImplicitHeight:
        Math.max(20, titleText.implicitHeight)
    readonly property real expandedHeaderImplicitWidth:
        Math.min(300, titleText.implicitWidth)
        + (hasSource ? 6 + Math.min(96, sourceText.implicitWidth) : 0)
        + (hasCount ? 6 + countText.implicitWidth : 0)
    readonly property real expandedCopyImplicitWidth: Math.max(
        expandedHeaderImplicitWidth,
        hasBody ? Math.min(390, bodyText.implicitWidth) : 0)
    readonly property real expandedImplicitWidth: 38 + 12
        + expandedCopyImplicitWidth + 12 + 27
    readonly property real expandedImplicitHeight: Math.max(38, 27,
        headerRow.implicitHeight + (hasBody ? 2 + Math.min(30,
            bodyText.implicitHeight) : 0))

    opacity: NotificationService.presentationVisible ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Design.contentRevealDuration
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        spacing: root.expanded ? 12 : 7

        Rectangle {
            Layout.preferredWidth: root.expanded ? 38 : 20
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: Qt.rgba(root.accent.r, root.accent.g,
                root.accent.b, root.expanded ? 0.16 : 0.12)

            Text {
                anchors.centerIn: parent
                text: root.notice?.severity === "success" ? "✓"
                    : root.notice?.severity === "info" ? "i" : "!"
                color: root.accent
                font.family: Design.fontDisplay
                font.pixelSize: root.expanded ? 16 : 10
                font.weight: Font.Bold
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: root.expanded ? 2 : 0

            RowLayout {
                id: headerRow
                Layout.fillWidth: true
                spacing: 6

                Text {
                    id: titleText
                    Layout.fillWidth: true
                    text: root.notice?.title || ""
                    color: Design.text
                    font.family: Design.fontDisplay
                    font.pixelSize: root.expanded ? 13 : 10
                    font.weight: Font.DemiBold
                    maximumLineCount: 1
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }

                Text {
                    id: sourceText
                    visible: root.expanded && root.hasSource
                    text: root.notice?.source || ""
                    color: Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    Layout.maximumWidth: 96
                }

                Text {
                    id: countText
                    visible: root.hasCount
                    text: "×" + root.notice.occurrenceCount
                    color: Design.textMuted
                    font.family: Design.fontMono
                    font.pixelSize: 9
                }
            }

            Text {
                id: bodyText
                Layout.fillWidth: true
                Layout.maximumHeight: root.expanded ? 30 : 0
                visible: root.expanded && root.hasBody
                text: root.notice?.message || ""
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 11
                maximumLineCount: 2
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
            }
        }

        Rectangle {
            visible: root.expanded
            Layout.preferredWidth: 27
            Layout.preferredHeight: 27
            Layout.alignment: Qt.AlignVCenter
            radius: 9
            color: closeHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

            Text {
                anchors.centerIn: parent
                text: "×"
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 14
            }

            HoverHandler { id: closeHover }
            TapHandler { onTapped: NotificationService.dismiss() }
        }
    }

    HoverHandler {
        id: noticeHover
        onHoveredChanged: NotificationService.setHovered(hovered)
    }

    Component.onCompleted: {
        registeredPresentationScreen = context?.screenName || "view"
        NotificationService.setPresented(registeredPresentationScreen, true)
    }
    Component.onDestruction:
        NotificationService.setPresented(registeredPresentationScreen, false)
}
