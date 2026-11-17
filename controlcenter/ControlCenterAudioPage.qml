import QtQuick
import qs.components
import qs.core
import qs.services.audio
import qs.services.controlcenter

FocusScope {
    id: root

    focus: true

    function pageSource(pageId) {
        if (pageId === "output" || pageId === "input")
            return Qt.resolvedUrl("../modules/audio/AudioDevicesPage.qml");
        if (pageId === "apps")
            return Qt.resolvedUrl("../modules/audio/AudioApplicationsPage.qml");
        if (pageId === "scenes")
            return Qt.resolvedUrl("../modules/audio/AudioScenesPage.qml");
        if (pageId === "effects")
            return Qt.resolvedUrl("../modules/audio/AudioEffectsPage.qml");
        return Qt.resolvedUrl("ControlCenterAudioLevels.qml");
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (pageLoader.item?.handleEscape?.()) {
                event.accepted = true;
                return;
            }
            if (AudioPanelService.currentPage !== "levels")
                AudioPanelService.selectPage("levels");
            else
                ControlCenterService.close();
            event.accepted = true;
        } else if (pageLoader.item?.handleNavigation?.(event.key, event.modifiers)) {
            event.accepted = true;
        }
    }
    Keys.priority: Keys.AfterItem

    IslandGlyph {
        id: titleGlyph
        x: Design.space20
        y: Design.space20
        width: 25
        height: 25
        name: "volumeHigh"
        glyphColor: Theme.accent
    }

    Text {
        x: titleGlyph.x + titleGlyph.width + Design.space12
        anchors.verticalCenter: titleGlyph.verticalCenter
        text: "Sound"
        color: Theme.textPrimary
        font.family: Design.fontDisplay
        font.pixelSize: Design.typeDisplay
        font.weight: Font.DemiBold
    }

    GlyphButton {
        anchors.right: parent.right
        anchors.rightMargin: Design.space16
        y: Design.space12
        width: 40
        height: 40
        glyph: "close"
        glyphSize: 16
        accessibleName: "Close sound controls"
        onActivated: ControlCenterService.close()
    }

    SegmentedPageBar {
        id: pageTabs
        x: Design.space20
        y: 66
        width: parent.width - Design.space20 * 2
        height: 38
        controlHeight: height
        cornerRadius: Design.radiusControl
        labelPixelSize: Design.typeLabel
        reducedMotion: Design.reducedMotion
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
            },
            {
                id: "scenes",
                label: "Scenes"
            },
            {
                id: "effects",
                label: "Effects"
            }
        ]
        currentPage: AudioPanelService.currentPage
        onPageSelected: pageId => AudioPanelService.selectPage(pageId)
    }

    Loader {
        id: pageLoader
        x: Design.space20
        y: pageTabs.y + pageTabs.height + Design.space12
        width: parent.width - Design.space20 * 2
        height: Math.max(0, parent.height - y - Design.space20)
        source: root.pageSource(AudioPanelService.currentPage)
        clip: true
    }
}
