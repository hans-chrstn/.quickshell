import QtQuick
import QtTest
import "../../modules/settings/NumericRange.js" as NumericRange

TestCase {
    name: "NumericRange"

    function test_clampsHighCustomValues() {
        compare(NumericRange.quantize(99, 0.25, 1.5, 0.05, 1), 1.5);
        compare(NumericRange.quantize(120, 1, 30, 1, 24), 30);
        compare(NumericRange.quantize(80, 1, 12, 0.5, 8), 12);
    }

    function test_clampsLowCustomValues() {
        compare(NumericRange.quantize(-4, 0.25, 1.5, 0.05, 1), 0.25);
    }

    function test_invalidInputKeepsCurrentValue() {
        compare(NumericRange.quantize("invalid", 1, 30, 1, 24), 24);
    }

    function test_quantizesAndSteps() {
        compare(NumericRange.quantize(1.273, 0.25, 1.5, 0.05, 1), 1.25);
        compare(NumericRange.stepped(1.25, 1, 0.25, 1.5, 0.05), 1.3);
        compare(NumericRange.stepped(1.5, 1, 0.25, 1.5, 0.05), 1.5);
        compare(NumericRange.stepped(0.25, -1, 0.25, 1.5, 0.05), 0.25);
    }
}
