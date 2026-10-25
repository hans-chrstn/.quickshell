import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services.display

ShellRoot {
    id: root
    readonly property string targetScreen: Quickshell.env("QS_DPMS_TEST_SCREEN") || ""
    property bool testedOff: false
    property bool testedOn: false

    function dispatchDpms(action) {
        if (!targetScreen.length || Quickshell.env("QS_TEST_MODE") !== "1")
            return false;
        const command = `hl.dsp.dpms({monitor="${targetScreen}", action="${action}"})`;
        Hyprland.dispatch(command);
        return true;
    }

    Component.onCompleted: {
        if (!targetScreen.length || !DisplayActivityService.setSyntheticIdle(false)) {
            Qt.quit();
            return;
        }
        DisplayActivityService.acquire(targetScreen);
        startTimer.start();
    }

    Connections {
        target: DisplayActivityService
        function onIdleChanged() {
            if (DisplayActivityService.idle && !root.testedOff) {
                root.testedOff = root.dispatchDpms("off");
                restoreTimer.start();
            }
        }
    }

    Timer {
        id: startTimer
        interval: 1200
        onTriggered: DisplayActivityService.setSyntheticIdle(true)
    }

    Timer {
        id: restoreTimer
        interval: 1600
        onTriggered: {
            root.testedOn = root.dispatchDpms("on");
            DisplayActivityService.clearSyntheticIdle();
            DisplayActivityService.release(root.targetScreen);
            Qt.quit();
        }
    }
}
