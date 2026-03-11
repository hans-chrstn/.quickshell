import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.core
import qs.ui.shared
import qs.ui.shared.effects
import qs.ui.shared.shapes

Item {
    id: root

    property bool active: DashboardManager.active
    
    property bool entryActive: false
    readonly property bool showContent: active && entryActive

    Timer {
        id: entryTimer
        interval: 50
        running: true
        onTriggered: root.entryActive = true
    }

    property int topFilletXOffset: 0
    property int topFilletYOffset: 0
    property int bottomFilletXOffset: 0
    property int bottomFilletYOffset: 15

    width: 400
    height: parent.height
    
    x: active ? 0 : -width
    z: 5
    
    onActiveChanged: {
        if (active) {
            SoundManager.playExpand()
        } else {
            SoundManager.playCollapse()
        }
    }

    states: [
        State {
            name: "active"
            when: root.showContent
            PropertyChanges { 
                target: root
                x: 0
            }
            PropertyChanges {
                target: backgroundLayer
                opacity: 1
            }
            PropertyChanges {
                target: dashboardContentArea
                opacity: 1
            }
        },
        State {
            name: "inactive"
            when: !root.showContent
            PropertyChanges { 
                target: root
                x: -root.width
            }
            PropertyChanges {
                target: backgroundLayer
                opacity: 0
            }
            PropertyChanges {
                target: dashboardContentArea
                opacity: 0
            }
        }
    ]

    transitions: [
        Transition {
            from: "inactive"; to: "active"
            ParallelAnimation {
                NumberAnimation { 
                    target: root
                    property: "x"
                    duration: ThemeManager.animationDuration
                    easing.type: ThemeManager.animationEasing
                }
                NumberAnimation {
                    targets: [backgroundLayer, dashboardContentArea]
                    property: "opacity"
                    duration: 150
                }
                NumberAnimation {
                    target: dashboardContentArea
                    property: "x"
                    from: -30
                    to: 0
                    duration: ThemeManager.animationDuration
                    easing.type: ThemeManager.animationEasing
                }
            }
        },
        Transition {
            from: "active"; to: "inactive"
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation { 
                        target: root
                        property: "x"
                        duration: ThemeManager.animationDuration
                        easing.type: ThemeManager.animationEasing
                    }
                    NumberAnimation {
                        targets: [backgroundLayer, dashboardContentArea]
                        property: "opacity"
                        duration: 150
                    }
                }
                ScriptAction {
                    script: DashboardManager.finalizeClose()
                }
            }
        }
    ]

    HoverHandler {
        id: dashboardHover
        onHoveredChanged: {
            if (!hovered) {
                DashboardManager.requestDismiss()
            } else {
                DashboardManager.cancelDismiss()
            }
        }
    }

    Item {
        id: backgroundLayer
        anchors.fill: parent
        opacity: 0

        Rectangle {
            id: bgRect
            anchors.fill: parent
            anchors.leftMargin: ThemeManager.globalThickness
            color: ThemeManager.backgroundColor
            opacity: 1.0

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.02) }
                    GradientStop { position: 0.1; color: "transparent" }
                    GradientStop { position: 0.9; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.1) }
                }
            }
        }

        InvertedCorner {
            id: topFillet
            anchors.top: parent.top
            anchors.topMargin: root.topFilletYOffset
            anchors.left: bgRect.right
            anchors.leftMargin: root.topFilletXOffset
            cornerRadius: ThemeManager.dynamicIslandCornerRadius
            cornerBackgroundColor: ThemeManager.backgroundColor
            visualRotation: 270
            z: 100
        }

        InvertedCorner {
            id: bottomFillet
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.bottomFilletYOffset
            anchors.left: bgRect.right
            anchors.leftMargin: root.bottomFilletXOffset
            cornerRadius: ThemeManager.dynamicIslandCornerRadius
            cornerBackgroundColor: ThemeManager.backgroundColor
            visualRotation: 180
            z: 100
        }
    }

    Item {
        id: dashboardContentArea
        anchors.fill: parent
        opacity: 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: ThemeManager.globalThickness
            spacing: 0

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 70
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: ThemeManager.surfaceSubtleColor }
                        GradientStop { position: 0.8; color: Qt.rgba(0, 0, 0, 0.15) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: ThemeManager.outlineVariantColor
                    opacity: 0.5
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 30
                    anchors.bottomMargin: 30
                    spacing: 20

                    Repeater {
                        model: DashboardManager.pages
                        delegate: BaseButton {
                            Layout.alignment: Qt.AlignHCenter
                            width: 44
                            height: 44
                            cornerRadius: 12
                            
                            readonly property var pageInfo: modelData
                            tooltip: pageInfo ? pageInfo.title : ""
                            
                            onClicked: {
                                DashboardManager.currentPage = index
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.cornerRadius
                                color: (pageInfo && DashboardManager.currentPage === index) 
                                    ? ThemeManager.accentColor 
                                    : "transparent"
                                
                                Behavior on color { ColorAnimation { duration: 250 } }
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.color: ThemeManager.outlinePrimaryColor
                                    border.width: 1
                                    visible: !pageInfo || DashboardManager.currentPage !== index
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: pageInfo ? pageInfo.icon : ""
                                color: (pageInfo && DashboardManager.currentPage === index) 
                                    ? ThemeManager.contentPrimaryColor 
                                    : ThemeManager.contentOnBackgroundColor
                                font.pixelSize: 22
                                z: 1
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 30
                    currentIndex: DashboardManager.realActive ? DashboardManager.currentPage : 0

                    ColumnLayout {
                        spacing: 25
                        
                        ColumnLayout {
                            spacing: 4
                            StyledLabel {
                                text: DashboardManager.realActive ? Qt.formatDateTime(new Date(), "dddd") : ""
                                type: "heading"
                                font.pixelSize: 28
                            }
                            StyledLabel {
                                text: DashboardManager.realActive ? Qt.formatDateTime(new Date(), "MMMM d, yyyy") : ""
                                type: "body"
                                opacity: 0.6
                            }
                        }

                        StyledCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                StyledLabel {
                                    text: "Upcoming Events"
                                    type: "title"
                                    font.pixelSize: 16
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: ThemeManager.outlineVariantColor
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Text {
                                        anchors.centerIn: parent
                                        text: "No events scheduled for today"
                                        color: ThemeManager.contentOnBackgroundColor
                                        opacity: 0.3
                                        font.pixelSize: 13
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 25
                        
                        StyledLabel {
                            text: "Audio Mixer"
                            type: "heading"
                            font.pixelSize: 28
                        }

                        ListView {
                            id: streamList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: AudioManager.streams
                            spacing: 15
                            clip: true
                            
                            delegate: StyledCard {
                                id: delegateRoot
                                width: streamList.width
                                height: 80
                                
                                readonly property int streamId: model.id
                                readonly property string streamName: model.name || "Application"
                                
                                readonly property bool isActuallyVisible: dashboardContentArea.opacity > 0.9
                                
                                readonly property PwNode streamNode: {
                                    if (!DashboardManager.realActive || !Pipewire.nodes || !Pipewire.nodes.values) return null;
                                    let nodes = Pipewire.nodes.values;
                                    for (let i = 0; i < nodes.length; i++) {
                                        if (nodes[i] && nodes[i].id === delegateRoot.streamId) return nodes[i];
                                    }
                                    return null;
                                }
                                
                                PwObjectTracker { 
                                    objects: (delegateRoot.streamNode && delegateRoot.isActuallyVisible) ? [delegateRoot.streamNode] : [] 
                                }
                                
                                Loader {
                                    anchors.fill: parent
                                    active: {
                                        let n = delegateRoot.streamNode;
                                        return delegateRoot.isActuallyVisible && n !== null && n !== undefined && n.ready && n.audio !== undefined;
                                    }
                                    
                                    sourceComponent: Item {
                                        anchors.fill: parent
                                        
                                        readonly property var nodeRef: delegateRoot.streamNode
                                        readonly property real vol: (nodeRef && nodeRef.ready && nodeRef.audio) ? nodeRef.audio.volume : 0.0
                                        readonly property bool isMuted: (nodeRef && nodeRef.ready && nodeRef.audio) ? nodeRef.audio.muted : false

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 15
                                            spacing: 8

                                            RowLayout {
                                                Layout.fillWidth: true
                                                StyledLabel { 
                                                    text: delegateRoot.streamName
                                                    type: "label"
                                                    elideMode: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                StyledLabel { 
                                                    text: Math.round(vol * 100) + "%"
                                                    type: "pillValue"
                                                    opacity: 0.6
                                                }
                                            }

                                            ValueSlider {
                                                Layout.fillWidth: true
                                                sliderValue: vol
                                                sliderIcon: isMuted ? ThemeManager.iconMute : ThemeManager.iconVolume
                                                sliderBarColor: ThemeManager.accentColor
                                                onSliderMoved: (val) => {
                                                    if (nodeRef && nodeRef.ready && nodeRef.audio) {
                                                        nodeRef.audio.volume = val
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: "Synchronizing..."
                                    type: "caption"
                                    opacity: 0.3
                                    visible: delegateRoot.isActuallyVisible && (!delegateRoot.streamNode || !delegateRoot.streamNode.ready || !delegateRoot.streamNode.audio)
                                }
                            }

                            footer: Item {
                                width: streamList.width
                                height: 40
                                visible: AudioManager.streams.count === 0
                                Text {
                                    anchors.centerIn: parent
                                    text: "No active application streams"
                                    color: ThemeManager.contentOnBackgroundColor
                                    opacity: 0.3
                                    font.pixelSize: 13
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 25
                        
                        StyledLabel {
                            text: "Clipboard"
                            type: "heading"
                            font.pixelSize: 28
                        }

                        ListView {
                            id: clipList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: ClipboardManager.history
                            spacing: 8
                            clip: true

                            delegate: BaseButton {
                                width: clipList.width
                                height: 60
                                cornerRadius: 12
                                hoverScale: 1.0
                                
                                readonly property string clipContent: modelData || ""
                                
                                onClicked: {
                                    if (clipContent) {
                                        ClipboardManager.copyToClipboard(clipContent)
                                        SoundManager.playSuccess()
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    color: parent.isHovered ? ThemeManager.surfaceStrongColor : ThemeManager.surfacePrimaryColor
                                    border.color: ThemeManager.outlineVariantColor
                                    border.width: 1
                                }

                                StyledLabel {
                                    anchors.fill: parent
                                    anchors.margins: 15
                                    text: clipContent.replace(/\n/g, " ")
                                    type: "body"
                                    elideMode: Text.ElideRight
                                    font.pixelSize: 13
                                }
                            }

                            footer: Item {
                                width: clipList.width
                                height: 40
                                visible: ClipboardManager.history.length === 0
                                Text {
                                    anchors.centerIn: parent
                                    text: "History is empty"
                                    color: ThemeManager.contentOnBackgroundColor
                                    opacity: 0.3
                                    font.pixelSize: 13
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 25
                        
                        StyledLabel {
                            text: "Scratchpad"
                            type: "heading"
                            font.pixelSize: 28
                        }

                        StyledCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            Flickable {
                                anchors.fill: parent
                                anchors.margins: 10
                                contentWidth: parent.width - 20
                                contentHeight: scratchpadEdit.height
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                
                                TapHandler {
                                    onTapped: scratchpadEdit.forceActiveFocus()
                                }

                                TextEdit {
                                    id: scratchpadEdit
                                    width: parent.width
                                    wrapMode: TextEdit.Wrap
                                    color: ThemeManager.contentOnBackgroundColor
                                    selectionColor: ThemeManager.accentColor
                                    selectedTextColor: ThemeManager.contentPrimaryColor
                                    font.pixelSize: 14
                                    font.family: ThemeManager.fontFamily
                                    
                                    readonly property string savedContent: NotesManager.content
                                    text: savedContent
                                    
                                    onTextChanged: {
                                        if (focus && DashboardManager.active) {
                                            NotesManager.content = text
                                        }
                                    }

                                    Text {
                                        text: "Type something quick..."
                                        color: Qt.rgba(1, 1, 1, 0.2)
                                        font: scratchpadEdit.font
                                        visible: scratchpadEdit.text === ""
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
