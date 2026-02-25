pragma Singleton
import QtQuick

QtObject {
    function clamp(value, min, max) {
        return Math.max(min, Math.min(max, value))
    }

    function lerp(start, end, amount) {
        return start + (end - start) * amount
    }

    function map(value, inMin, inMax, outMin, outMax) {
        return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
    }
}
