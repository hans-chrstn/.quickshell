import QtQuick
import QtTest
import "../../services/audio/EasyEffectsProtocol.js" as EasyEffectsProtocol

TestCase {
    name: "EasyEffectsProtocol"

    function test_capabilityPrefersNativeAndNeverClaimsAStoppedBackend() {
        compare(EasyEffectsProtocol.capability(true, true, false, false), {
            installed: true,
            installation: "native",
            running: false,
            backend: "none",
            eventDriven: true,
            pollingIntervalMs: 0
        });
        compare(EasyEffectsProtocol.capability(false, true, true, false).installation, "flatpak");
        compare(EasyEffectsProtocol.capability(false, false, true, false).installation, "unknown");
        verify(EasyEffectsProtocol.capability(false, false, true, false).installed);
        compare(EasyEffectsProtocol.capability(false, false, false, false).installation, "none");
        compare(EasyEffectsProtocol.capability(true, false, false, true).backend, "cli");
        compare(EasyEffectsProtocol.capability(true, false, true, true).backend, "local-server");
    }

    function test_commandsUseTheDocumentedLocalServerProtocol() {
        compare(EasyEffectsProtocol.bypassQuery(), "get_global_bypass");
        compare(EasyEffectsProtocol.bypassMutation(true), "global_bypass:1");
        compare(EasyEffectsProtocol.bypassMutation(false), "global_bypass:0");
        compare(EasyEffectsProtocol.bypassMutation("true"), "");
        compare(EasyEffectsProtocol.activePresetQuery("output"), "get_last_loaded_preset:output");
        compare(EasyEffectsProtocol.activePresetQuery("source"), "");
        compare(EasyEffectsProtocol.loadPresetMutation("input", "Voice"), "load_preset:input:Voice");
    }

    function test_presetNamesRejectProtocolDelimitersAndControls() {
        compare(EasyEffectsProtocol.safePresetName("  Night Voice  "), "Night Voice");
        compare(EasyEffectsProtocol.safePresetName("unsafe:name"), "");
        compare(EasyEffectsProtocol.safePresetName("unsafe\nname"), "");
        compare(EasyEffectsProtocol.safePresetName(""), "");
        compare(EasyEffectsProtocol.safePresetName("x".repeat(161)), "");
    }

    function test_inventoryIsSafeUniqueAndDeterministic() {
        compare(EasyEffectsProtocol.normalizedPresets(["Voice", " music ", "VOICE", "bad:name", "Default"]), ["Default", "music", "Voice"]);
    }

    function test_absolutePathNormalizationIsBoundedAndSafe() {
        compare(EasyEffectsProtocol.normalizedAbsolutePaths([" /a/ ", "relative", "/a", "/b//"], 8), ["/a", "/b"]);
        compare(EasyEffectsProtocol.normalizedAbsolutePaths(["/a", "/b", "/c"], 2), ["/a", "/b"]);
    }

    function test_presetInventoryUsesOnlyPipelineJsonPaths() {
        const inventory = EasyEffectsProtocol.presetInventoryFromPaths(["/home/user/.local/share/easyeffects/output/Music.json", "/home/user/.local/share/easyeffects/input/Voice.json", "/home/user/.var/app/com.github.wwmm.easyeffects/data/easyeffects/output/music.json", "/home/user/.local/share/easyeffects/output/bad:name.json", "/home/user/.local/share/easyeffects/output/nested/Ignore.json", "/home/user/.local/share/easyeffects/output/Ignore.txt"]);
        compare(inventory.output, ["Music"]);
        compare(inventory.input, ["Voice"]);
    }

    function test_installationEvidenceNeverExecutesOrGuesses() {
        compare(EasyEffectsProtocol.installation("/run/current-system/sw/bin/easyeffects\n", 1, "", "/run/current-system/sw/bin/flatpak"), {
            nativeInstalled: true,
            nativePath: "/run/current-system/sw/bin/easyeffects",
            flatpakInstalled: false,
            flatpakPath: "/run/current-system/sw/bin/flatpak"
        });
        compare(EasyEffectsProtocol.installation("", 0, "/home/user/.var/app/com.github.wwmm.easyeffects\n", "/usr/bin/flatpak"), {
            nativeInstalled: false,
            nativePath: "",
            flatpakInstalled: true,
            flatpakPath: "/usr/bin/flatpak"
        });
        verify(!EasyEffectsProtocol.installation("relative/easyeffects", 0, "", "").nativeInstalled);
    }

    function test_cliCommandsAreDirectAndInstallationAware() {
        compare(EasyEffectsProtocol.cliCommand("native", "/usr/bin/easyeffects", "", "query-bypass", null), ["/usr/bin/easyeffects", "-b", "3"]);
        compare(EasyEffectsProtocol.cliCommand("native", "/usr/bin/easyeffects", "", "set-bypass", true), ["/usr/bin/easyeffects", "-b", "1"]);
        compare(EasyEffectsProtocol.cliCommand("flatpak", "", "/usr/bin/flatpak", "query-preset", "input"), ["/usr/bin/flatpak", "run", "com.github.wwmm.easyeffects", "-a", "input"]);
        compare(EasyEffectsProtocol.cliCommand("flatpak", "", "/usr/bin/flatpak", "load-preset", "Voice"), ["/usr/bin/flatpak", "run", "com.github.wwmm.easyeffects", "-l", "Voice"]);
        compare(EasyEffectsProtocol.cliCommand("native", "relative", "", "query-bypass", null), []);
        compare(EasyEffectsProtocol.cliCommand("native", "/usr/bin/easyeffects", "", "query-preset", "invalid"), []);
    }

    function test_cliPresetLoadRejectsCrossPipelineAmbiguity() {
        verify(EasyEffectsProtocol.cliLoadPlan("input", "Voice", ["Music"], ["Voice"], true, false).accepted);
        compare(EasyEffectsProtocol.cliLoadPlan("input", "Default", ["Default"], ["Default"], true, false).code, "ambiguous-cli-preset");
        compare(EasyEffectsProtocol.cliLoadPlan("output", "Missing", ["Music"], ["Voice"], true, false).code, "preset-unavailable");
        compare(EasyEffectsProtocol.cliLoadPlan("output", "Music", ["Music"], ["Voice"], false, false).code, "cli-unavailable");
    }

    function test_bypassResponseIsStrict() {
        verify(EasyEffectsProtocol.parseBypassResponse("1\n").bypassed);
        verify(!EasyEffectsProtocol.parseBypassResponse("2").bypassed);
        compare(EasyEffectsProtocol.parseBypassResponse("0").code, "invalid-response");
        compare(EasyEffectsProtocol.parseBypassResponse("").code, "empty-response");
    }

    function test_emptyAndNonePresetResponsesAreExplicit() {
        const empty = EasyEffectsProtocol.parsePresetResponse("\n");
        verify(empty.accepted);
        compare(empty.preset, "");
        compare(empty.code, "none");
        compare(EasyEffectsProtocol.parsePresetResponse("None").preset, "");
        compare(EasyEffectsProtocol.parsePresetResponse("Voice\n").preset, "Voice");
    }

    function test_loadPlanFailsClosedBeforeMutation() {
        compare(EasyEffectsProtocol.loadPlan("invalid", "Voice", ["Voice"], true, false).code, "invalid-pipeline");
        compare(EasyEffectsProtocol.loadPlan("input", "bad:name", ["bad:name"], true, false).code, "invalid-preset");
        compare(EasyEffectsProtocol.loadPlan("input", "Voice", ["Voice"], false, false).code, "server-unavailable");
        compare(EasyEffectsProtocol.loadPlan("input", "Voice", ["Voice"], true, true).code, "busy");
        compare(EasyEffectsProtocol.loadPlan("input", "Missing", ["Voice"], true, false).code, "preset-unavailable");
    }

    function test_loadPlanIncludesIndependentConfirmation() {
        const plan = EasyEffectsProtocol.loadPlan("input", "Voice", ["Default", "Voice"], true, false);
        verify(plan.accepted);
        compare(plan.command, "load_preset:input:Voice");
        compare(plan.confirmationCommand, "get_last_loaded_preset:input");
    }

    function test_confirmationRejectsCliStyleFalseSuccess() {
        verify(EasyEffectsProtocol.confirmPreset("Voice", "Voice").accepted);
        compare(EasyEffectsProtocol.confirmPreset("Voice", "Default").code, "mismatch");
        compare(EasyEffectsProtocol.confirmPreset("Voice", "").code, "none");
        compare(EasyEffectsProtocol.confirmPreset("bad:name", "bad:name").accepted, false);
    }
}
