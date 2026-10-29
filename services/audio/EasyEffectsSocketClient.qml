import QtQuick
import Quickshell.Io

Item {
    id: root

    required property string socketPath
    property bool busy: false
    property int token: 0
    property string command: ""
    property string response: ""
    property bool expectResponse: false

    signal completed(int token, string command, string response)
    signal failed(int token, string code, string message)

    visible: false
    width: 0
    height: 0

    function request(nextCommand, needsResponse, nextToken) {
        const normalized = String(nextCommand || "").trim();
        if (busy || normalized.length === 0 || socketPath.length === 0)
            return false;
        token = Math.max(0, Math.trunc(Number(nextToken) || 0));
        command = normalized;
        response = "";
        expectResponse = needsResponse === true;
        busy = true;
        requestTimeout.restart();
        socketLoader.active = true;
        return true;
    }

    function acceptChunk(value) {
        if (!busy || !expectResponse)
            return;
        response += String(value || "");
        if (response.length > 4096) {
            fail("response-too-large", "The EasyEffects server response exceeded the safe limit.");
            return;
        }
        responseSettle.restart();
    }

    function finish() {
        if (!busy)
            return;
        const completedToken = token;
        const completedCommand = command;
        const completedResponse = response;
        reset();
        completed(completedToken, completedCommand, completedResponse);
    }

    function fail(code, message) {
        if (!busy)
            return;
        const failedToken = token;
        reset();
        failed(failedToken, code, message);
    }

    function reset() {
        requestTimeout.stop();
        responseSettle.stop();
        writeSettle.stop();
        if (socketLoader.item?.connected)
            socketLoader.item.connected = false;
        socketLoader.active = false;
        busy = false;
        token = 0;
        command = "";
        response = "";
        expectResponse = false;
    }

    Loader {
        id: socketLoader
        active: false
        onLoaded: item.connected = true
        sourceComponent: Component {
            Socket {
                path: root.socketPath
                parser: SplitParser {
                    splitMarker: ""
                    onRead: data => root.acceptChunk(data)
                }
                onConnectionStateChanged: {
                    if (!root.busy || !connected)
                        return;
                    write(root.command + "\n");
                    flush();
                    if (!root.expectResponse)
                        writeSettle.restart();
                }
                onError: root.fail("server-unavailable", "The EasyEffects local server is unavailable.")
            }
        }
    }

    Timer {
        id: requestTimeout
        interval: 800
        onTriggered: root.fail("server-timeout", "The EasyEffects local server did not respond in time.")
    }

    Timer {
        id: responseSettle
        interval: 20
        onTriggered: root.finish()
    }

    Timer {
        id: writeSettle
        interval: 40
        onTriggered: root.finish()
    }

    Component.onDestruction: reset()
}
