import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.ui.shared
import qs.ui.shared.effects
import qs.ui.features.island.app

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (visible && bloom.progress > 0.9) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property string screenName: (root.screen) ? root.screen.name : ""
    property bool entryActive: false
    readonly property bool showContent: LauncherManager.active && !LauncherManager.isClosing && entryActive
    visible: (LauncherManager.active || bloom.progress > 0.01) && (ViewManager.lastActiveScreenName === screenName)

    onVisibleChanged: {
        if (visible) {
            entryTimer.restart()
        } else {
            entryActive = false
        }
    }

    Timer {
        id: entryTimer
        interval: 50
        onTriggered: {
            entryActive = true
            searchInput.forceActiveFocus()
        }
    }

    Item {
        id: contentArea
        anchors.fill: parent
        opacity: root.showContent ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        OrganicBlobs {
            anchors.fill: parent
            color1: Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.15)
            color2: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.2)
            color3: ThemeManager.backgroundColor
            opacity: 0.4
        }

        AdvancedGlass {
            id: glassBackground
            anchors.fill: parent
            blurRadius: 64
            cornerRadius: 0
            overlayOpacity: 0.75
            overlayColor: "#050505"
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            width: Math.min(parent.width - 120, 1000)

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                Layout.bottomMargin: 50

                Rectangle {
                    id: matteOuter
                    anchors.fill: parent
                    radius: 32
                    color: "#1c1c1e"
                }

                Rectangle {
                    id: matteInner
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 31
                    color: "#101012"
                }

                Rectangle {
                    id: matteBorder
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 31
                    color: "transparent"
                    border.color: ThemeManager.outlineStrongColor
                    border.width: 1
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 16

                    StyledLabel {
                        text: ThemeManager.iconSearch
                        type: "heading"
                        font.pixelSize: 22
                        opacity: searchInput.activeFocus ? 1.0 : 0.3
                        customColor: ThemeManager.accentColor
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: "#f5f5f7"
                        font.family: ThemeManager.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        selectionColor: ThemeManager.accentColor
                        text: LauncherManager.searchText

                        onTextChanged: {
                            LauncherManager.searchText = text
                        }

                        onAccepted: {
                            if (LauncherManager.model.count > 0) {
                                let app = LauncherManager.model.get(0).app
                                if (!WindowManager.focusApplication(app.id)) {
                                    app.execute()
                                }
                                LauncherManager.close()
                            }
                        }

                        StyledLabel {
                            text: "Search apps..."
                            type: "title"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            letterSpacing: -0.35
                            opacity: 0.12
                            visible: !searchInput.text && !searchInput.activeFocus
                        }
                    }
                }
            }

            GridView {
                id: appGrid
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, root.height * 0.6)
                Layout.alignment: Qt.AlignHCenter

                model: LauncherManager.model
                cellWidth: 130
                cellHeight: 150
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: delegateRoot
                    width: appGrid.cellWidth
                    height: appGrid.cellHeight

                    opacity: 0
                    scale: 0.8

                    transform: Translate {
                        id: cascadeTranslate
                        y: 30
                    }

                    SequentialAnimation {
                        running: root.visible
                        PauseAnimation {
                            duration: Math.max(0, (index % 8) * 30 + (Math.floor(index / 8) * 40))
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: delegateRoot
                                property: "opacity"
                                to: 1.0
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: delegateRoot
                                property: "scale"
                                to: 1.0
                                duration: 500
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.2
                            }
                            NumberAnimation {
                                target: cascadeTranslate
                                property: "y"
                                to: 0
                                duration: 500
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.2
                            }
                        }
                    }

                    BaseButton {
                        id: launcherBtn
                        anchors.fill: parent
                        anchors.margins: 8
                        cornerRadius: 20
                        highlightCornerRadius: 14
                        hoverScale: 1.05
                        tooltip: model.app.name
                        highlightTarget: launcherIconComp

                        onClicked: {
                            if (!WindowManager.focusApplication(model.app.id)) {
                                model.app.execute()
                            }
                            LauncherManager.close()
                        }

                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: {
                                if (!launcherContextMenuLoader.item) {
                                    launcherContextMenuLoader.active = true
                                }
                                if (launcherContextMenuLoader.item) {
                                    launcherContextMenuLoader.item.popup()
                                }
                            }
                        }

                        Loader {
                            id: launcherContextMenuLoader
                            active: false
                            sourceComponent: Component {
                                AppIslandContextMenu {
                                    app: model.app
                                    delegateRoot: delegateRoot
                                    onClosed: {
                                        launcherContextMenuLoader.active = false
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            AppIslandIcon {
                                id: launcherIconComp
                                app: model.app
                                iconSize: 64
                                cornerRadius: 14
                                isHovered: launcherBtn.isHovered
                                isRunning: typeof WindowManager !== "undefined" ? WindowManager.isApplicationRunning(model.app.id) : false
                            }

                            StyledLabel {
                                text: model.app.name
                                type: "body"
                                font.weight: Font.DemiBold
                                font.pixelSize: 11
                                letterSpacing: -0.15
                                Layout.preferredWidth: 110
                                horizontalAlignment: Text.AlignHCenter
                                elideMode: Text.ElideRight
                                opacity: launcherBtn.isHovered ? 1.0 : 0.55
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }
                        }
                    }
                }
            }
        }
    }

    IrisBloom {
        id: bloom
        anchors.fill: parent
        source: contentArea
        progress: root.showContent ? 1.0 : 0.0
        cornerRadius: 0
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: {
            LauncherManager.close()
        }
    }
}
