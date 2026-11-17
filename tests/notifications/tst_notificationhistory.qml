import QtQuick
import QtTest
import "../../services/notifications/NotificationHistory.js" as History

TestCase {
    name: "NotificationHistory"

    function notice(id, source, title, time, message = "Body") {
        return {
            id: id,
            source: source,
            title: title,
            message: message,
            severity: "info",
            screenName: "DP-1",
            occurrenceCount: 1,
            createdAtMs: time
        };
    }

    function test_persistsAndGroupsByApplication() {
        let entries = [];
        entries = History.insert(entries, notice("1", "Mail", "First", 100), 100);
        entries = History.insert(entries, notice("2", "Chat", "Message", 200), 200);
        entries = History.insert(entries, notice("3", "Mail", "Second", 300), 300);
        compare(entries.length, 3);
        const groups = History.groups(entries);
        compare(groups.length, 2);
        compare(groups[0].source, "Mail");
        compare(groups[0].items.length, 2);
        compare(groups[0].items[0].title, "Second");
        compare(groups[1].source, "Chat");
    }

    function test_replacementAndRetentionBounds() {
        let entries = History.insert([], notice("1", "Mail", "First", 100), 100);
        entries = History.insert(entries, notice("1", "Mail", "Updated", 100), 200);
        compare(entries.length, 1);
        compare(entries[0].title, "Updated");
        compare(entries[0].latestAtMs, 200);
        entries = History.merge([notice("old", "App", "Expired", 1)], entries, History.maximumAgeMs + 201);
        compare(entries.length, 0);
        for (let i = 1; i <= History.maximumEntries + 10; i++)
            entries = History.insert(entries, notice("n" + i, "App", "Title", i), i);
        compare(entries.length, History.maximumEntries);
        compare(entries[0].id, "n" + (History.maximumEntries + 10));
    }

    function test_lockSafeProjectionOmitsBodies() {
        const entries = History.insert([], notice("1", "Messages", "New message", 100, "secret"), 100);
        const safe = History.lockSafe(entries);
        compare(safe[0].title, "New message");
        verify(!Object.prototype.hasOwnProperty.call(safe[0], "message"));
        compare(History.remove(entries, "1").length, 0);
    }

    function test_invalidStoredRecordsCannotEnterHistory() {
        const invalid = [
            {
                id: "bad",
                title: "Bad",
                createdAtMs: -100000000,
                latestAtMs: -100000000
            }
        ];
        compare(History.merge(invalid, [], History.maximumAgeMs + 100).length, 0);
    }
}
