import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    property bool active: false
    property int editingPresetIndex: -1

    onActiveChanged: {
        if (!active) {
            root.editingPresetIndex = -1
        }
    }

    anchors.fill: parent
    anchors.margins: 20
    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        StyledLabel {
            text: "AI Chat"
            type: "heading"
            font.pixelSize: 28
        }

        Item { Layout.fillWidth: true }

        BaseButton {
            width: 32
            height: 32
            cornerRadius: 16
            visible: AIManager.isConfigured

            onClicked: viewMenuLoader.active = true

            StyledLabel {
                anchors.centerIn: parent
                text: "󰍉"
                type: "icon"
                font.pixelSize: 16
                opacity: parent.isHovered ? 1.0 : 0.3
            }
        }
    }

    Loader {
        id: viewMenuLoader
        active: false

        onLoaded: item.popup()

        sourceComponent: BaseContextMenu {
            width: 160

            onOpened: ViewManager.dashboardContentHovered = true
            onClosed: {
                viewMenuLoader.active = false
            }

            MenuItem {
                contentItem: StyledLabel {
                    text: "Chat"
                    type: "body"
                    font.pixelSize: 13
                    font.weight: AIManager.view === "chat" ? Font.DemiBold : Font.Medium
                    leftPadding: 12
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.highlighted ? ThemeManager.surfaceVariantStrongColor : "transparent"
                    radius: ThemeManager.radiusSmall
                }
                onTriggered: { AIManager.view = "chat"; close() }
            }

            MenuItem {
                contentItem: StyledLabel {
                    text: "History"
                    type: "body"
                    font.pixelSize: 13
                    font.weight: AIManager.view === "history" ? Font.DemiBold : Font.Medium
                    leftPadding: 12
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.highlighted ? ThemeManager.surfaceVariantStrongColor : "transparent"
                    radius: ThemeManager.radiusSmall
                }
                onTriggered: { AIManager.view = "history"; close() }
            }

            MenuItem {
                contentItem: StyledLabel {
                    text: "Providers"
                    type: "body"
                    font.pixelSize: 13
                    font.weight: AIManager.view === "settings" ? Font.DemiBold : Font.Medium
                    leftPadding: 12
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.highlighted ? ThemeManager.surfaceVariantStrongColor : "transparent"
                    radius: ThemeManager.radiusSmall
                }
                onTriggered: { AIManager.view = "settings"; close() }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: AIManager.isConfigured && AIManager.view !== "history"

        StyledLabel {
            text: {
                if (!AIManager.isConfigured) return "Configure your AI provider to begin"
                if (AIManager.view === "settings") return "Providers"
                return AIManager.configuredName + " · " + AIManager.configuredModel
            }
            type: "caption"
            opacity: 0.3
            Layout.fillWidth: true
        }
    }

    Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        active: !AIManager.isConfigured || AIManager.view === "settings"
        visible: active
        sourceComponent: dashboardSettingsComponent
    }

    Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        active: AIManager.isConfigured && AIManager.view === "history"
        visible: active
        sourceComponent: DashboardAIHistory { }
    }

    Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        active: AIManager.isConfigured && AIManager.view === "chat"
        visible: active
        sourceComponent: DashboardAIChat { }
    }

    Component {
        id: dashboardSettingsComponent

        Flickable {
            id: setupFlickable
            anchors.fill: parent
            contentHeight: setupLayout.implicitHeight + 40
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: setupLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 12

                StyledLabel {
                    Layout.fillWidth: true
                    text: "AI Providers"
                    type: "title"
                    letterSpacing: -0.35
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledLabel {
                    text: AIManager.presets.count + " provider(s) saved"
                    type: "caption"
                    opacity: 0.3
                    visible: AIManager.presets.count > 0
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                ListView {
                    id: presetList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(60, presetList.contentHeight)
                    visible: AIManager.presets.count > 0
                    spacing: 6
                    clip: true
                    interactive: contentHeight > height
                    model: AIManager.presets

                    delegate: ExpandableCard {
                        width: presetList.width
                        expanded: root.editingPresetIndex === index
                        expandedHeight: 280

                        MouseArea {
                            anchors.fill: parent
                            propagateComposedEvents: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!expanded) {
                                    AIManager.activatePreset(index)
                                }
                            }
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 44
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                StyledLabel {
                                    text: name
                                    type: "body"
                                    font.weight: Font.DemiBold
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    elideMode: Text.ElideRight
                                }

                                StyledLabel {
                                    text: modelName
                                    type: "caption"
                                    font.pixelSize: 10
                                    opacity: 0.4
                                    Layout.fillWidth: true
                                    elideMode: Text.ElideRight
                                }
                            }

                            BaseButton {
                                width: 32
                                height: 32
                                cornerRadius: 16
                                z: 1

                                onClicked: {
                                    presetCtxMenuLoader.presetIndex = index
                                    presetCtxMenuLoader.active = true
                                }

                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: "󰇙"
                                    type: "icon"
                                    font.pixelSize: 14
                                    opacity: parent.isHovered ? 1.0 : 0.3
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.topMargin: 44
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 6
                            visible: expanded

                            StyledInput { id: editName; Layout.fillWidth: true; Layout.preferredHeight: 38; placeholder: "Name"; text: name }
                            StyledInput { id: editUrl; Layout.fillWidth: true; Layout.preferredHeight: 38; placeholder: "API URL"; text: url }
                            StyledInput { id: editModel; Layout.fillWidth: true; Layout.preferredHeight: 38; placeholder: "Model"; text: modelName }
                            StyledInput { id: editKey; Layout.fillWidth: true; Layout.preferredHeight: 38; placeholder: "API Key"; text: key; isPassword: true }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                BaseButton {
                                    Layout.fillWidth: true
                                    height: 36
                                    cornerRadius: 18

                                    onClicked: {
                                        AIManager.updatePreset(index, editName.text, editUrl.text, editModel.text, editKey.text)
                                        root.editingPresetIndex = -1
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 18
                                        color: parent.isHovered ? ThemeManager.accentColor : "#25282e"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    StyledLabel {
                                        anchors.centerIn: parent
                                        text: "Save"
                                        type: "body"
                                        font.weight: Font.DemiBold
                                        font.pixelSize: 13
                                        customColor: parent.parent.isHovered ? "#111111" : ThemeManager.contentOnBackgroundColor
                                    }
                                }

                                BaseButton {
                                    Layout.fillWidth: true
                                    height: 36
                                    cornerRadius: 18
                                    onClicked: root.editingPresetIndex = -1
                                    StyledLabel {
                                        anchors.centerIn: parent; text: "Cancel"; type: "body"
                                        font.weight: Font.DemiBold; font.pixelSize: 13; opacity: 0.5
                                    }
                                }
                            }
                        }

                        Loader {
                            id: presetCtxMenuLoader
                            active: false
                            property int presetIndex: -1
                            onLoaded: item.popup()

                            sourceComponent: BaseContextMenu {
                                width: 180
                                onOpened: ViewManager.dashboardContentHovered = true
                                onClosed: {
                                    presetCtxMenuLoader.active = false
                                }

                                MenuItem {
                                    contentItem: StyledLabel {
                                        text: "Connect"
                                        type: "body"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        leftPadding: 12
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        color: parent.highlighted ? ThemeManager.surfaceVariantStrongColor : "transparent"
                                        radius: ThemeManager.radiusSmall
                                    }
                                    onTriggered: {
                                        AIManager.activatePreset(presetCtxMenuLoader.presetIndex)
                                        close()
                                    }
                                }

                                MenuItem {
                                    contentItem: StyledLabel {
                                        text: "Edit"
                                        type: "body"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        leftPadding: 12
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        color: parent.highlighted ? ThemeManager.surfaceVariantStrongColor : "transparent"
                                        radius: ThemeManager.radiusSmall
                                    }
                                    onTriggered: {
                                        root.editingPresetIndex = presetCtxMenuLoader.presetIndex
                                        close()
                                    }
                                }

                                MenuSeparator { }

                                MenuItem {
                                    contentItem: StyledLabel {
                                        text: "Delete"
                                        type: "body"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        customColor: ThemeManager.dangerColor
                                        leftPadding: 12
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        color: parent.highlighted ? ThemeManager.surfaceVariantStrongColor : "transparent"
                                        radius: ThemeManager.radiusSmall
                                    }
                                    onTriggered: {
                                        AIManager.deletePreset(presetCtxMenuLoader.presetIndex)
                                        close()
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: ThemeManager.outlinePrimaryColor
                    opacity: 0.3
                    visible: AIManager.presets.count > 0
                }

                StyledLabel {
                    Layout.fillWidth: true
                    text: "Add Provider"
                    type: "label"
                    font.weight: Font.DemiBold
                }

                Item {
                    id: addForm
                    Layout.fillWidth: true
                    Layout.preferredHeight: addFormLayout.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: addFormLayout
                        anchors.fill: parent
                        spacing: 8

                        StyledInput { id: addName; Layout.fillWidth: true; Layout.preferredHeight: 40; placeholder: "Preset name (e.g. DeepSeek)" }
                        StyledInput { id: addUrl; Layout.fillWidth: true; Layout.preferredHeight: 40; placeholder: "API URL" }
                        StyledInput { id: addModel; Layout.fillWidth: true; Layout.preferredHeight: 40; placeholder: "Model (e.g. deepseek-chat)" }
                        StyledInput { id: addKey; Layout.fillWidth: true; Layout.preferredHeight: 40; placeholder: "API Key (sk-...)"; isPassword: true }

                        BaseButton {
                            Layout.alignment: Qt.AlignHCenter
                            width: 160
                            height: 40
                            cornerRadius: 20
                            onClicked: {
                                AIManager.addPreset(addName.text, addUrl.text, addModel.text, addKey.text)
                                addName.text = ""; addUrl.text = ""; addModel.text = ""; addKey.text = ""
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 20
                                color: parent.isHovered ? ThemeManager.accentColor : "#1c1c1e"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            StyledLabel {
                                anchors.centerIn: parent
                                text: "Add Provider"
                                type: "body"
                                font.weight: Font.DemiBold
                                font.pixelSize: 14
                                customColor: parent.parent.isHovered ? "#111111" : ThemeManager.contentOnBackgroundColor
                            }
                        }
                    }
                }
            }
        }
    }
}
