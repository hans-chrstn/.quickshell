import QtQuick
import QtTest
import "../../core/LocalCalendar.js" as LocalCalendar

TestCase {
    name: "LocalCalendar"

    function test_normalizesExternalParts() {
        const parts = LocalCalendar.normalizeParts({
            day: -1,
            minute: 9999,
            timezoneOffset: -240,
            year: 2026,
            month: 9,
            date: 1
        })
        compare(parts.day, 6)
        compare(parts.minute, 1439)
        compare(parts.timezoneOffset, -240)
        compare(parts.year, 2026)
        compare(parts.month, 9)
        compare(parts.date, 1)
    }

    function test_partsReflectsRealDateObject() {
        const timestamp = new Date(2026, 8, 1, 13, 45, 20).getTime()
        const parts = LocalCalendar.parts(timestamp)
        compare(parts.year, 2026)
        compare(parts.month, 9)
        compare(parts.date, 1)
        compare(parts.minute, 13 * 60 + 45)
    }
}
