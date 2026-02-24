import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

ColumnLayout {
    id: root
    spacing: -10
    Layout.alignment: Qt.AlignHCenter

    readonly property color accent: ColorService.accent

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    function getOrdinalSuffix(day) {
        if (day > 3 && day < 21) return 'TH';
        switch (day % 10) {
            case 1:  return "ST";
            case 2:  return "ND";
            case 3:  return "RD";
            default: return "TH";
        }
    }

    function formattedDate() {
        const d = sysClock.date;
        const dayName = Qt.formatDateTime(d, "dddd").toUpperCase();
        const monthName = Qt.formatDateTime(d, "MMMM").toUpperCase();
        const dayNum = d.getDate();
        return `${dayName}, ${monthName} ${dayNum}${getOrdinalSuffix(dayNum)}`;
    }

    Text {
        id: timeText
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(sysClock.date, "hh:mm")
        color: "white"
        font.pixelSize: ThemeService.lockClockFontSize
        font.weight: Font.Black
        font.letterSpacing: -2
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: formattedDate()
        color: root.accent
        opacity: ThemeService.lockDateOpacity
        font.pixelSize: ThemeService.lockDateFontSize
        font.letterSpacing: ThemeService.lockDateLetterSpacing
        font.weight: Font.Bold
    }
}
