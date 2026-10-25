import QtQuick
import Quickshell
import qs.modules.settings

ShellRoot {
    id: root

    property bool completed: false

    SettingNumericStepper {
        id: stepper
        value: 1
        from: 0.25
        to: 1.5
        stepSize: 0.05
        suffix: "×"
    }

    Timer {
        interval: 0
        running: true
        onTriggered: {
            root.completed = true;
            if (stepper.normalizedValue !== 1 || stepper.formattedValue !== "1.00") {
                console.error("NUMERIC_STEPPER_FAILED:unexpected-state");
                Qt.exit(1);
                return;
            }
            console.log("NUMERIC_STEPPER_RESULT:constructed");
            Qt.quit();
        }
    }

    Timer {
        interval: 5000
        running: !root.completed
        onTriggered: {
            console.error("NUMERIC_STEPPER_FAILED:timeout");
            Qt.exit(1);
        }
    }
}
