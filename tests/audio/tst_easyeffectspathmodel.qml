import QtQuick
import QtTest
import "../../services/audio/EasyEffectsPathModel.js" as EasyEffectsPathModel

TestCase {
    name: "EasyEffectsPathModel"

    function node(id, name, sink, properties) {
        return {
            id: id,
            name: name,
            isSink: sink,
            isStream: false,
            ready: true,
            audio: ({
                    volume: 0.5
                }),
            properties: properties || ({})
        };
    }

    function effectNode(id, role, driverId) {
        return node(id, role === "output" ? "easyeffects_sink" : "easyeffects_source", role === "output", {
            "application.id": "com.github.wwmm.easyeffects",
            "media.class": role === "output" ? "Audio/Sink" : "Audio/Source/Virtual",
            "node.virtual": "true",
            "node.driver-id": String(driverId)
        });
    }

    function physicalNode(id, role) {
        return node(id, role === "output" ? "alsa_output.usb" : "alsa_input.usb", role === "output", {
            "device.api": "alsa",
            "media.class": role === "output" ? "Audio/Sink" : "Audio/Source",
            "node.virtual": "false"
        });
    }

    function test_physicalDefaultsRemainDirect() {
        const physical = physicalNode(10, "output");
        compare(EasyEffectsPathModel.resolution("output", physical, [physical]), {
            role: "output",
            defaultId: 10,
            targetId: 10,
            virtualDefault: false,
            mapped: false,
            code: "direct"
        });
    }

    function test_exactPhysicalDriverIsMappedForBothDirections() {
        const output = effectNode(20, "output", 10);
        const physicalOutput = physicalNode(10, "output");
        const input = effectNode(21, "input", 11);
        const physicalInput = physicalNode(11, "input");

        compare(EasyEffectsPathModel.resolution("output", output, [output, physicalOutput]).targetId, 10);
        compare(EasyEffectsPathModel.resolution("output", output, [output, physicalOutput]).code, "mapped-driver");
        compare(EasyEffectsPathModel.resolution("input", input, [input, physicalInput]).targetId, 11);
        compare(EasyEffectsPathModel.resolution("input", input, [input, physicalInput]).code, "mapped-driver");
    }

    function test_selfDriverKeepsTheVirtualControlPath() {
        const effect = effectNode(20, "output", 20);
        const physicalA = physicalNode(10, "output");
        const physicalB = physicalNode(11, "output");
        const resolution = EasyEffectsPathModel.resolution("output", effect, [effect, physicalA, physicalB]);

        compare(resolution.targetId, 20);
        compare(resolution.code, "virtual-self-driver");
        verify(!resolution.mapped);
    }

    function test_missingOrUnsafeDriverNeverChoosesAnotherDevice() {
        const effect = effectNode(20, "output", 99);
        const physicalA = physicalNode(10, "output");
        const wrongDirection = physicalNode(99, "input");
        const missing = EasyEffectsPathModel.resolution("output", effect, [effect, physicalA]);
        const wrong = EasyEffectsPathModel.resolution("output", effect, [effect, physicalA, wrongDirection]);

        compare(missing.targetId, 20);
        compare(missing.code, "virtual-driver-unavailable");
        compare(wrong.targetId, 20);
        compare(wrong.code, "virtual-driver-unavailable");
    }

    function test_unreadyOrVirtualDriverCannotMasqueradeAsPhysical() {
        const effect = effectNode(20, "output", 30);
        const unready = physicalNode(30, "output");
        unready.ready = false;
        const virtualTarget = effectNode(30, "output", 30);

        compare(EasyEffectsPathModel.resolution("output", effect, [effect, unready]).targetId, 20);
        compare(EasyEffectsPathModel.resolution("output", effect, [effect, virtualTarget]).targetId, 20);
    }
}
