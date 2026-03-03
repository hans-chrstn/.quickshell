import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

ColumnLayout {
    id: root
    
    spacing: -10
    Layout.alignment: Qt.AlignHCenter

    readonly property color accentColor: ThemeManager.accentColor

    SystemClock {
        id: internalSystemClock
        precision: SystemClock.Minutes
    }

    function getDayOrdinalSuffix(dayOfMonth) {
        if (dayOfMonth > 3 && dayOfMonth < 21) return 'TH';
        switch (dayOfMonth % 10) {
            case 1:  return "ST";
            case 2:  return "ND";
            case 3:  return "RD";
            default: return "TH";
        }
    }

    function getFormattedDate() {
        let currentDate = internalSystemClock.date;
        let dayName = Qt.formatDateTime(currentDate, "dddd").toUpperCase();
        let monthName = Qt.formatDateTime(currentDate, "MMMM").toUpperCase();
        let dayOfMonth = currentDate.getDate();
        return `${dayName}, ${monthName} ${dayOfMonth}${getDayOrdinalSuffix(dayOfMonth)}`;
    }

    Text {
        id: lockScreenTimeLabel
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(internalSystemClock.date, "hh:mm")
        color: ThemeManager.contentOnBackgroundColor
        font.pixelSize: ThemeManager.lockClockFontSize
        font.weight: Font.Black
        font.letterSpacing: -2
    }

    Text {
        id: lockScreenDateLabel
        Layout.alignment: Qt.AlignHCenter
        text: root.getFormattedDate()
        color: root.accentColor
        opacity: ThemeManager.lockDateOpacity
        font.pixelSize: ThemeManager.lockDateFontSize
        font.letterSpacing: ThemeManager.lockDateLetterSpacing
        font.weight: Font.Bold
    }
}
