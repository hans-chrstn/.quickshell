import QtQuick

Timer {
    id: root

    required property Item targetItem
    property var activeService: null
    property int maxAttempts: 6
    property int attempts: 0

    interval: 100
    repeat: false

    function startFocus(): void {
        attempts = 0
        if (targetItem) {
            targetItem.forceActiveFocus()
            if (!targetItem.activeFocus && maxAttempts > 0) {
                attempts = 1
                restart()
            }
        }
    }

    onTriggered: {
        if (activeService && !activeService.opened)
            return

        if (targetItem) {
            targetItem.forceActiveFocus()
            if (!targetItem.activeFocus && attempts < maxAttempts) {
                attempts += 1
                restart()
            }
        }
    }
}
