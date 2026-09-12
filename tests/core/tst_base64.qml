import QtQuick
import QtTest
import "../../core/Base64.js" as Base64

TestCase {
    name: "Base64"

    function test_decodesAsciiAndUtf8() {
        compare(Base64.decode("WyJ7cGF0aH0iLCJzcGFjZWQgdmFsdWUiXQ=="),
            "[\"{path}\",\"spaced value\"]")
        compare(Base64.decode("IuaXpeacrOiqniI="), "\"日本語\"")
    }

    function test_rejectsMalformedOversizedAndInvalidUtf8() {
        compare(Base64.decode("not-base64"), null)
        compare(Base64.decode("////"), null)
        compare(Base64.decode("A".repeat(Base64.maximumEncodedLength + 4)),
            null)
    }
}
