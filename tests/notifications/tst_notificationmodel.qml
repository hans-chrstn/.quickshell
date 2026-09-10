import QtQuick
import QtTest
import "../../services/notifications/NotificationModel.js" as Model

TestCase {
    name: "NotificationModel"

    function test_normalizesAndBoundsInput() {
        const result = Model.enqueue([], {
            severity: "DANGER",
            title: "  Hello\nworld  ",
            message: "Body\nline",
            durationMs: 999999
        }, 100, 1)
        verify(result.accepted)
        compare(result.notice.severity, "info")
        compare(result.notice.title, "Hello world")
        compare(result.notice.message, "Body line")
        compare(result.notice.durationMs, Model.maximumDurationMs)
    }

    function test_rejectsEmptyAndDeduplicates() {
        verify(!Model.enqueue([], {}, 100, 1).accepted)
        const first = Model.enqueue([], { severity: "error", title: "Failed",
            dedupeKey: "save", source: "editor" }, 100, 1)
        const second = Model.enqueue(first.queue, { severity: "error",
            title: "Failed again", dedupeKey: "save", source: "editor" },
            200, 2)
        compare(second.queue.length, 1)
        compare(second.notice.id, first.notice.id)
        compare(second.notice.occurrenceCount, 2)
        compare(second.notice.title, "Failed again")
    }

    function test_queueIsBoundedAndPreservesCurrent() {
        let queue = []
        for (let index = 0; index < Model.maximumQueueLength + 3; ++index)
            queue = Model.enqueue(queue, { title: "Notice " + index },
                index + 1, index + 1).queue
        compare(queue.length, Model.maximumQueueLength)
        compare(queue[0].title, "Notice 0")
        compare(queue[queue.length - 1].title,
            "Notice " + (Model.maximumQueueLength + 2))
    }
}
