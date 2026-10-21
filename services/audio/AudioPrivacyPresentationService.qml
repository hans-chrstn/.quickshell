pragma Singleton

import QtQuick
import Quickshell
import qs.services
import "AudioPrivacyPresentationModel.js" as AudioPrivacyPresentationModel

Singleton {
    id: root

    readonly property var presentation: AudioPrivacyPresentationModel.presentation(AudioService.privacy)
    readonly property bool active: presentation.active === true
    property string targetScreenName: ""

    function synchronizeTarget() {
        if (!active) {
            targetScreenName = "";
            return;
        }
        targetScreenName = ScreenService.resolve(targetScreenName);
    }

    function snapshot() {
        return {
            active: active,
            targetScreenName: targetScreenName,
            clientCount: presentation.clientCount,
            primaryName: presentation.primaryName,
            title: presentation.title,
            detail: presentation.detail,
            eventDriven: true,
            pollingIntervalMs: 0
        };
    }

    onActiveChanged: synchronizeTarget()

    Connections {
        target: Quickshell
        function onScreensChanged() {
            root.synchronizeTarget();
        }
    }
}
