import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared
import qs.ui.screens.dashboard.calendar

ColumnLayout {
    id: root

    property bool active: false

    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

    onActiveChanged: {
        if (!active) {
            eventEditor.active = false
        }
    }

    CalendarHeader {
        id: calendarHeader
        isEditorActive: eventEditor.active
        
        onSyncTriggered: {
            CalendarManager.triggerSync()
            SoundManager.playSuccess()
        }
        
        onAddTriggered: {
            eventEditor.active = !eventEditor.active
        }
    }

    CalendarGrid {
        id: calendarGrid
        Layout.fillWidth: true
    }

    EventEditor {
        id: eventEditor
        active: false
        eventDate: {
            if (!CalendarManager) {
                return new Date()
            }
            return CalendarManager.selectedDate
        }
    }

    EventListModule {
        id: eventListModule
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
