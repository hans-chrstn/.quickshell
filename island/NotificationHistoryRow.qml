import QtQuick
import qs.components
import qs.core

Item {
    id: root

    required property var group
    property bool expandedLayout: false
    property bool groupExpanded: false
    property string expandedNoticeId: ""
    property real groupReveal: groupExpanded ? 1 : 0
    readonly property bool stacked: group.count > 1
    readonly property var latest: group.items[0]
    readonly property bool singleBodyVisible: !stacked && expandedNoticeId === latest.id && latest.message.length > 0
    readonly property color severityColor: latest.severity === "error" ? Theme.danger : latest.severity === "warning" ? Theme.warning : latest.severity === "success" ? Theme.success : Theme.accent

    signal groupRequested(string key)
    signal noticeRequested(string id)
    signal removeRequested(string id)

    clip: true
    implicitHeight: mainCard.height + (stacked ? 6 : 0) + (stacked ? members.implicitHeight * Math.max(0, Math.min(1, groupReveal)) : 0)

    Behavior on groupReveal {
        enabled: !Design.reducedMotion
        SpatialSpring {
            phase: "morph"
        }
    }

    Rectangle {
        visible: root.stacked && !root.groupExpanded
        x: Design.space12
        y: 6
        width: parent.width - Design.space24
        height: mainCard.height
        radius: Design.radiusGrouped
        color: Theme.fillQuiet
        border.color: Theme.separatorQuiet
    }

    Rectangle {
        visible: root.stacked && !root.groupExpanded
        x: Design.space6
        y: 3
        width: parent.width - Design.space12
        height: mainCard.height
        radius: Design.radiusGrouped
        color: Theme.fillSubtle
        border.color: Theme.separatorQuiet
    }

    Rectangle {
        id: mainCard
        width: parent.width
        height: Design.notificationRowHeight + (root.singleBodyVisible ? singleBody.implicitHeight + Design.space12 : 0)
        clip: true
        radius: Design.radiusGrouped
        color: mainPointer.containsMouse ? Theme.fillElevated : Theme.fillSubtle
        border.color: root.groupExpanded || root.singleBodyVisible ? Theme.tintBorder(root.severityColor) : Theme.separatorQuiet

        Behavior on height {
            enabled: !Design.reducedMotion
            SpatialSpring {
                phase: "morph"
            }
        }

        IslandGlyph {
            x: Design.space12
            y: (Design.notificationRowHeight - height) / 2
            width: 16
            height: 16
            name: "bell"
            glyphColor: root.severityColor
        }

        Text {
            id: titleText
            x: 40
            y: root.latest.source.length > 0 ? 8 : (Design.notificationRowHeight - height) / 2
            width: parent.width - x - (root.stacked ? 58 : root.expandedLayout ? 54 : 18)
            text: root.latest.source.length > 0 ? root.latest.source : root.latest.title
            color: Theme.textPrimary
            font.family: Design.fontDisplay
            font.pixelSize: Design.typeBody
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        Text {
            visible: root.latest.source.length > 0
            x: titleText.x
            y: 27
            width: titleText.width
            text: root.latest.title
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeLabel
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        Rectangle {
            visible: root.stacked
            x: parent.width - width - Design.space12
            y: (Design.notificationRowHeight - height) / 2
            width: Math.max(27, countText.implicitWidth + Design.space12)
            height: 25
            radius: height / 2
            color: Theme.fillStrong

            Text {
                id: countText
                anchors.centerIn: parent
                text: root.group.count
                color: Theme.textPrimary
                font.family: Design.fontText
                font.pixelSize: Design.typeLabel
            }
        }

        Text {
            id: singleBody
            visible: root.latest.message.length > 0
            x: titleText.x
            y: Design.notificationRowHeight
            width: parent.width - x - Design.space12
            text: root.latest.message
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeBody
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            opacity: root.singleBodyVisible ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Design.springContentFadeInDuration
                }
            }
        }

        MouseArea {
            id: mainPointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.stacked ? root.groupRequested(root.group.key) : root.noticeRequested(root.latest.id)
            Accessible.role: Accessible.Button
            Accessible.name: root.stacked ? "Expand " + (root.latest.source || root.latest.title) + " notification stack" : "Expand " + root.latest.title
        }

        GlyphButton {
            visible: root.expandedLayout && !root.stacked
            x: parent.width - width - Design.space4
            y: (Design.notificationRowHeight - height) / 2
            width: 34
            height: 34
            glyph: "close"
            glyphSize: 13
            accessibleName: "Remove " + root.latest.title
            onActivated: root.removeRequested(root.latest.id)
        }
    }

    Column {
        id: members
        visible: root.stacked && root.groupReveal > 0.01
        opacity: Math.max(0, Math.min(1, root.groupReveal))
        x: Design.space12
        y: mainCard.height + Design.space6
        width: parent.width - Design.space12
        spacing: Design.space4

        Repeater {
            model: root.stacked && (root.groupExpanded || root.groupReveal > 0.01) ? root.group.items : []

            Rectangle {
                required property var modelData
                readonly property bool bodyVisible: root.expandedNoticeId === modelData.id && modelData.message.length > 0
                width: members.width
                height: Math.max(38, memberTitle.implicitHeight + Design.space16) + (bodyVisible ? memberBody.implicitHeight + Design.space8 : 0)
                clip: true
                radius: Design.radiusControl
                color: memberPointer.containsMouse ? Theme.fillElevated : Theme.fillQuiet
                border.color: bodyVisible ? Theme.tintBorder(root.severityColor) : Theme.separatorQuiet

                Behavior on height {
                    enabled: !Design.reducedMotion
                    SpatialSpring {
                        phase: "morph"
                    }
                }

                Text {
                    id: memberTitle
                    x: Design.space12
                    y: Design.space8
                    width: parent.width - Design.space24 - (root.expandedLayout ? 34 : 0)
                    text: modelData.title
                    color: Theme.textPrimary
                    font.family: Design.fontText
                    font.pixelSize: Design.typeBody
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                Text {
                    id: memberBody
                    visible: modelData.message.length > 0
                    x: memberTitle.x
                    y: Math.max(38, memberTitle.implicitHeight + Design.space16)
                    width: memberTitle.width
                    text: modelData.message
                    color: Theme.textSecondary
                    font.family: Design.fontText
                    font.pixelSize: Design.typeBody
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    opacity: parent.bodyVisible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Design.springContentFadeInDuration
                        }
                    }
                }

                MouseArea {
                    id: memberPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.noticeRequested(modelData.id)
                    Accessible.role: Accessible.Button
                    Accessible.name: "Expand " + modelData.title
                }

                GlyphButton {
                    visible: root.expandedLayout
                    x: parent.width - width - Design.space4
                    y: (Math.max(38, memberTitle.implicitHeight + Design.space16) - height) / 2
                    width: 32
                    height: 32
                    glyph: "close"
                    glyphSize: 12
                    accessibleName: "Remove " + modelData.title
                    onActivated: root.removeRequested(modelData.id)
                }
            }
        }
    }
}
