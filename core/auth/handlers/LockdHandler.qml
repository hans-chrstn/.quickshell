pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pam
import qs.core.auth

Singleton {
    id: root
    signal ready()
    signal success()
    signal failed()
    property string user: ""
    property bool _isActive: false

    PamContext {
        id: pam
        config: "login"
        user: root.user
        
        onCompleted: (result) => {
            if (result === PamResult.Success) {
                root.success()
            } else {
                root.failed()
            }
            root._isActive = false
        }

        onResponseRequiredChanged: {
            if (responseRequired) {
                root.ready()
            }
        }
    }

    function start() {
        pam.abort()
        pam.start()
        root._isActive = true
    }

    function respond(password) {
        pam.respond(password)
    }
}
