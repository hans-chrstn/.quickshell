# Read-only DPMS protocol prototype

Standalone C++ Wayland client; no Quickshell integration, surface, periodic timer,
GPU dependency, or power-setting request. Subscribes to
`zwlr_output_power_manager_v1`, discovers outputs dynamically, and prints initial
and subsequent compositor-reported power states. Requires wl_output v4 for names;
older outputs are explicitly reported unsupported. Registry removal releases the
output and its subscription; protocol failure invalidates its known state.

Build using the project's locked nixpkgs (works before these files are staged):

```sh
nix build --impure --no-link --print-out-paths --expr 'let f = builtins.getFlake "/home/jin/.config/quickshell"; pkgs = import f.inputs.nixpkgs { system = builtins.currentSystem; }; in import /home/jin/.config/quickshell/tests/display/dpms-observer { inherit pkgs; }'
```

Run `timeout 30s <printed-store-path>/bin/dpms-observer` in the Wayland session.
Exit 124 from timeout is expected for a healthy subscriber. Exit 2 means the
manager is absent; exit 1 means connection/setup/dispatch failure.
Generated protocol code comes from the packaged wlr-protocols XML; no generated
files or binaries belong in this repository.

## Evidence — 2026-09-14

Tested against the running Hyprland 0.56.2, commit
`efb50993780079460b0cbed1363e2166a2de1d9f`:

- Protocol advertised at version 1; DP-1, DP-3 and HDMI-A-1 initial states
  matched a separate `hyprctl -j monitors` query.
- External DP-1 off/on produced `changed ... power=off` then `power=on`.
  The other two outputs produced no spurious power changes.
- A newly started observer while DP-1 was off correctly reported initial off.
- DP-1 was restored automatically after both bounded tests.
- Ten idle seconds: CPU ticks stayed 0, voluntary context switches stayed 3,
  involuntary switches stayed 1, RSS stayed 4176 KiB. This is a short observation,
  not a claim of zero overhead under all workloads.
- Built with `-Wall -Wextra -Werror`; focused format check and project QML lint
  passed. QML lint does not accept C++ inputs; the initial incorrect invocation
  was corrected to its normal QML selection.
- Hyprland's legacy `dispatch dpms off DP-1` syntax was rejected. Tests used
  `hyprctl dispatch 'hl.dsp.dpms({monitor="DP-1", action="off"})'` and the
  corresponding `on` action. The observer itself never sends these commands.

- Physical unplug/replug passed with the user disconnecting DP-3: the observer
  reported removal of registry output 73, discovered replacement output 75 with
  the same name, and received a fresh initial `power=on` event. DP-1 and HDMI-A-1
  emitted no spurious changes. A separate monitor query confirmed all three
  connected and powered on afterward.

Still pending: compositor disconnection/restart and a live unsupported-protocol
compositor test. The Quickshell adapter now owns one private Wayland connection
through `WallpaperMonitorPowerService`; its QML lifecycle test passed twenty
enable/disable cycles, and the production harness passed startup-off, off/on,
consumer teardown, and re-acquisition. This observes compositor DPMS state, not
independent electrical measurement of the display hardware.
