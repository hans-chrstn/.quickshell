import QtQuick

QtObject {
    required property string providerId
    property bool enabled: true

    function search(query) { return [] }
    function execute(result) { }
}
