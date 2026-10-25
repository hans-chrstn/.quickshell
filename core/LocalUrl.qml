pragma Singleton

import QtQuick
import "LocalUrl.js" as LocalUrlLogic

QtObject {
    function fromPath(value) {
        return LocalUrlLogic.fromPath(value)
    }
}
