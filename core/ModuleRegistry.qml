import QtQuick

QtObject {
    id: root

    required property list<IslandModule> modules

    function select(attentionOnly) {
        let winner = null;

        for (let i = 0; i < modules.length; ++i) {
            const candidate = modules[i];
            if (!candidate || !candidate.arbitrationActive || (attentionOnly && !candidate.attention))
                continue;
            if (!winner || candidate.priority > winner.priority || (candidate.priority === winner.priority && candidate.moduleId < winner.moduleId)) {
                winner = candidate;
            }
        }

        return winner;
    }

    readonly property IslandModule current: select(false)
    readonly property IslandModule attentive: select(true)
    readonly property bool attentionRequested: attentive !== null
}
