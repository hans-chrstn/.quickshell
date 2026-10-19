import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services.audio

Item {
    id: root

    property QtObject context: null
    readonly property real collapsedImplicitWidth: 180
    readonly property real collapsedImplicitHeight: 22
    readonly property real expandedImplicitWidth: 600
    readonly property real expandedImplicitHeight: contentColumn.implicitHeight + 8
    readonly property real pageViewportHeight: 300

    focus: true
    Component.onCompleted: focusRetrier.startFocus()

    function pageSource(pageId) {
        if (pageId === "output" || pageId === "input")
            return Qt.resolvedUrl("AudioDevicesPage.qml");
        if (pageId === "apps")
            return Qt.resolvedUrl("AudioApplicationsPage.qml");
        return Qt.resolvedUrl("AudioMasterPage.qml");
    }

    FocusRetrier {
        id: focusRetrier
        targetItem: root
        activeService: AudioPanelService
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (AudioPanelService.currentPage === "apps" && pageLoader.item?.handleEscape?.()) {
                event.accepted = true;
                return;
            }
            if (AudioPanelService.currentPage !== "levels")
                AudioPanelService.selectPage("levels");
            else
                AudioPanelService.close();
            event.accepted = true;
        } else if (AudioPanelService.currentPage === "apps" && pageLoader.item?.handleNavigation?.(event.key, event.modifiers)) {
            event.accepted = true;
        }
    }
    Keys.priority: Keys.AfterItem

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 10

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 42

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Sound"
                color: Theme.textPrimary
                font.family: Design.fontDisplay
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }

            GlyphButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                glyph: "close"
                glyphSize: 16
                accessibleName: "Close Sound"
                onActivated: AudioPanelService.close()
            }
        }

        SegmentedPageBar {
            Layout.preferredWidth: 360
            Layout.alignment: Qt.AlignHCenter
            controlHeight: 36
            cornerRadius: 12
            labelPixelSize: 11
            accentColor: Theme.textSecondary
            pages: [
                {
                    id: "levels",
                    label: "Levels"
                },
                {
                    id: "output",
                    label: "Output"
                },
                {
                    id: "input",
                    label: "Input"
                },
                {
                    id: "apps",
                    label: "Apps"
                }
            ]
            currentPage: AudioPanelService.currentPage
            onPageSelected: pageId => AudioPanelService.selectPage(pageId)
        }

        Loader {
            id: pageLoader
            Layout.fillWidth: true
            Layout.minimumHeight: root.pageViewportHeight
            Layout.preferredHeight: root.pageViewportHeight
            Layout.maximumHeight: root.pageViewportHeight
            source: root.pageSource(AudioPanelService.currentPage)
        }
    }
}
