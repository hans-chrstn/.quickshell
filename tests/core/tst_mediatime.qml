import QtQuick
import QtTest
import "../../services/media/MediaTime.js" as MediaTime

TestCase {
    name: "MediaTime"

    function test_formatsShortAndLongTracks() {
        compare(MediaTime.clock(9), "0:09");
        compare(MediaTime.clock(3599), "59:59");
        compare(MediaTime.clock(3600), "1:00:00");
        compare(MediaTime.clock(7325), "2:02:05");
    }

    function test_clampsSeekPositionToTrack() {
        compare(MediaTime.boundedSeconds(-15, 200), 0);
        compare(MediaTime.boundedSeconds(230, 200), 200);
        compare(MediaTime.fraction(50, 200), 0.25);
    }

    function test_missingOrInvalidTimelineHasNoProgress() {
        compare(MediaTime.fraction(40, 0), 0);
        compare(MediaTime.fraction(NaN, 200), 0);
        compare(MediaTime.clock(NaN), "0:00");
    }
}
