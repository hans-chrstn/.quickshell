import QtQuick
import QtTest
import "../../core/JsonCopy.js" as JsonCopy

TestCase {
    name: "JsonCopy"

    function test_nestedValuesAreIndependent() {
        const source = {
            list: [{ value: 1 }],
            map: { enabled: true }
        }
        const copied = JsonCopy.value(source)
        copied.list[0].value = 2
        copied.map.enabled = false
        compare(source.list[0].value, 1)
        verify(source.map.enabled)
    }

    function test_primitivesAndNullArePreserved() {
        compare(JsonCopy.value(null), null)
        compare(JsonCopy.value("wallpaper"), "wallpaper")
        compare(JsonCopy.value(12), 12)
        compare(JsonCopy.value(false), false)
    }

    function test_excessiveDepthIsBounded() {
        let source = ({ leaf: true })
        for (let index = 0; index < JsonCopy.maximumDepth + 4; ++index)
            source = ({ child: source })
        let copied = JsonCopy.value(source)
        for (let index = 0; index < JsonCopy.maximumDepth; ++index)
            copied = copied?.child
        compare(copied, null)
    }
}
