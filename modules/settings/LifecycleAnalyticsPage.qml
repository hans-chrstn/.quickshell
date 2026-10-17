import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components.analytics
import qs.components.scrolling
import qs.core
import qs.services.lifecycle

SettingPage {
    id: root

    property var snapshot: ({
            resources: ({}),
            adaptivePolicy: {
                enabled: false,
                plan: {
                    usedUnits: 0,
                    budgetUnits: 0
                }
            }
        })

    readonly property var rows: {
        const values = Object.keys(snapshot.resources ?? {}).map(id => snapshot.resources[id]);
        values.sort(function (left, right) {
            const leftRank = root.stateRank(left);
            const rightRank = root.stateRank(right);
            if (leftRank !== rightRank)
                return leftRank - rightRank;
            return String(left.resourceId).localeCompare(String(right.resourceId));
        });
        return values;
    }

    readonly property var summary: {
        let active = 0;
        let retained = 0;
        let eligible = 0;
        let unloaded = 0;
        for (let index = 0; index < rows.length; ++index) {
            const record = rows[index];
            if (record.active)
                ++active;
            else if (record.adaptiveCandidate)
                ++eligible;
            else if (record.loaded)
                ++retained;
            else if (!record.loaded)
                ++unloaded;
        }
        const plan = snapshot.adaptivePolicy?.plan ?? {};
        return {
            active: active,
            retained: retained,
            eligible: eligible,
            unloaded: unloaded,
            used: plan.usedUnits ?? 0,
            budget: plan.budgetUnits ?? 0
        };
    }

    readonly property var stateSegments: [
        {
            label: "Active",
            value: summary.active,
            color: Theme.success
        },
        {
            label: "Retained",
            value: summary.retained,
            color: Theme.accent
        },
        {
            label: "Eligible",
            value: summary.eligible,
            color: Theme.warning
        },
        {
            label: "Unloaded",
            value: summary.unloaded,
            color: Theme.textSecondary
        }
    ]

    readonly property var budgetSegments: {
        const used = Math.max(0, Number(summary.used ?? 0));
        const budget = Math.max(0, Number(summary.budget ?? 0));
        return [
            {
                label: "Used",
                value: Math.min(used, budget),
                color: Theme.warning
            },
            {
                label: "Available",
                value: Math.max(0, budget - used),
                color: Theme.fillElevated
            }
        ];
    }

    function stateRank(record) {
        if (record.active)
            return 0;
        if (record.adaptiveCandidate)
            return 1;
        if (record.loaded)
            return 2;
        return 3;
    }

    function stateLabel(record) {
        if (record.active)
            return "Active";
        if (record.adaptiveCandidate)
            return "Eligible";
        if (record.loaded)
            return "Retained";
        return "Unloaded";
    }

    function stateColor(record) {
        if (record.active)
            return Theme.success;
        if (record.adaptiveCandidate)
            return Theme.warning;
        if (record.loaded)
            return Theme.accent;
        return Theme.textSecondary;
    }

    function refresh() {
        snapshot = LifecycleService.snapshot();
    }

    Component.onCompleted: refresh()

    Connections {
        target: LifecycleService
        function onResourcesChanged() {
            root.refresh();
        }
        function onAdaptiveEnabledChanged() {
            root.refresh();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        SettingsHeader {
            title: "Lifecycle"
        }

        LifecycleSummaryStrip {
            Layout.fillWidth: true
            summary: root.summary
        }

        SegmentedBarGraph {
            Layout.fillWidth: true
            segments: root.stateSegments
            title: "Resource distribution"
            valueText: root.rows.length + " total"
        }

        SegmentedBarGraph {
            Layout.fillWidth: true
            segments: root.budgetSegments
            title: "Inactive resource budget"
            valueText: root.summary.used + "/" + root.summary.budget + " · " + (root.snapshot.adaptivePolicy?.plan?.candidateCount ?? 0) + " candidates"
            showLegend: false
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: root.rows.length + " session resources"
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 9
            }

            Text {
                text: (root.snapshot.adaptivePolicy?.enabled ? "Adaptive on" : "Adaptive off") + " · retain " + (root.snapshot.adaptivePolicy?.plan?.retained?.length ?? 0) + " · evict " + (root.snapshot.adaptivePolicy?.plan?.evicted?.length ?? 0)
                color: root.snapshot.adaptivePolicy?.enabled ? Theme.success : Theme.textSecondary
                font.family: Design.fontMono
                font.pixelSize: 8
            }
        }

        ListView {
            id: resourceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.rows
            boundsBehavior: Flickable.StopAtBounds

            SmoothScrollBehavior {
                target: resourceList
            }
            ScrollEdgeFeedback {
                target: resourceList
            }
            ScrollBar.vertical: MinimalScrollBar {}

            delegate: LifecycleResourceRow {
                required property var modelData
                width: resourceList.width - 8
                record: modelData
                stateLabel: root.stateLabel(modelData)
                stateColor: root.stateColor(modelData)
            }
        }
    }
}
