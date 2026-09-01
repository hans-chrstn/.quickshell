import QtQuick

QtObject {
    id: root

    required property list<IslandModule> modules

    readonly property IslandModule current: {
        let winner = null

        for (let i = 0; i < modules.length; ++i) {
            const candidate = modules[i]
            if (!candidate || !candidate.active)
                continue

            if (!winner || candidate.priority > winner.priority
                    || (candidate.priority === winner.priority
                        && candidate.moduleId < winner.moduleId)) {
                winner = candidate
            }
        }

        return winner
    }

    readonly property bool attentionRequested: current?.attention ?? false
}
