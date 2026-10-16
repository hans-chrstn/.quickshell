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
    readonly property real expandedImplicitWidth: 640
    readonly property real expandedImplicitHeight: contentColumn.implicitHeight + 8

    focus: true
    Component.onCompleted: focusRetrier.startFocus()

    function pageSource(pageId) {
        return pageId === "output" || pageId === "input" ? Qt.resolvedUrl("AudioDevicesPage.qml") : Qt.resolvedUrl("AudioMasterPage.qml");
    }

    FocusRetrier {
        id: focusRetrier
        targetItem: root
        activeService: AudioPanelService
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (AudioPanelService.currentPage !== "levels")
                AudioPanelService.selectPage("levels");
            else
                AudioPanelService.close();
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 14

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 50

            IslandGlyph {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                name: "volumeHigh"
                glyphColor: Design.blue
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 44
                anchors.verticalCenter: parent.verticalCenter
                text: "Sound"
                color: Design.text
                font.family: Design.fontDisplay
                font.pixelSize: 23
                font.weight: Font.DemiBold
            }

            GlyphButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36
                glyph: "close"
                glyphSize: 19
                accessibleName: "Close audio controls"
                onActivated: AudioPanelService.close()
            }
        }

        SegmentedPageBar {
            Layout.preferredWidth: 440
            Layout.alignment: Qt.AlignHCenter
            controlHeight: 44
            cornerRadius: 14
            labelPixelSize: 12
            accentColor: Design.textMuted
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
                }
            ]
            currentPage: AudioPanelService.currentPage
            onPageSelected: pageId => AudioPanelService.selectPage(pageId)
        }

        Loader {
            id: pageLoader
            Layout.fillWidth: true
            Layout.preferredHeight: 356
            source: root.pageSource(AudioPanelService.currentPage)
        }
    }
}
