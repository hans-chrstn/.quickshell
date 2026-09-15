{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      quickshell,
      self,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          qtMultimedia = pkgs.kdePackages.qtmultimedia;
          qtImageFormats = pkgs.kdePackages.qtimageformats;
          libvaUtils = pkgs.libva-utils;
          ffmpeg = pkgs.ffmpeg-full;
          kirigami = pkgs.kdePackages.kirigami.unwrapped;
          qmlQuickshell = quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
          mediaEngine = pkgs.stdenv.mkDerivation {
            pname = "qs-mediaengine";
            version = "0.1.0";
            src = ./plugins/mediaengine;
            nativeBuildInputs = [
              pkgs.cmake
              pkgs.ninja
            ];
            buildInputs = [
              pkgs.qt6.qtbase
              pkgs.qt6.qtdeclarative
              pkgs.sqlite
            ];
            dontWrapQtApps = true;
          };
          displayPowerPlugin = pkgs.stdenv.mkDerivation {
            pname = "qs-displaypower";
            version = "0.1.0";
            src = ./plugins/displaypower;
            nativeBuildInputs = [
              pkgs.cmake
              pkgs.ninja
              pkgs.pkg-config
              pkgs.wayland-scanner
            ];
            buildInputs = [
              pkgs.qt6.qtbase
              pkgs.qt6.qtdeclarative
              pkgs.wayland
            ];
            cmakeFlags = [ "-DWLR_PROTOCOLS=${pkgs.wlr-protocols}/share/wlr-protocols" ];
            dontWrapQtApps = true;
          };
          cachePlugin = pkgs.stdenv.mkDerivation {
            pname = "qs-cache";
            version = "0.1.0";
            src = ./plugins/cache;
            nativeBuildInputs = [
              pkgs.cmake
              pkgs.ninja
            ];
            buildInputs = [
              pkgs.qt6.qtbase
              pkgs.qt6.qtdeclarative
              pkgs.sqlite
            ];
            dontWrapQtApps = true;
          };
        in
        rec {
          config = pkgs.stdenv.mkDerivation {
            name = "quickshell-config";
            src = ./.;
            installPhase = ''
              mkdir -p $out
              cp -r * $out/
            '';
          };

          quickshell = pkgs.symlinkJoin {
            name = "quickshell-wrapped";
            meta.mainProgram = "qs";
            paths = [
              qmlQuickshell
              mediaEngine
              cachePlugin
              displayPowerPlugin
            ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              for bin in $out/bin/*; do
                wrapProgram "$bin" \
                  --prefix QML2_IMPORT_PATH : "${qtMultimedia}/lib/qt-6/qml" \
                  --prefix QML2_IMPORT_PATH : "${mediaEngine}/lib/qt-6/qml" \
                  --prefix QML2_IMPORT_PATH : "${cachePlugin}/lib/qt-6/qml" \
                  --prefix QML2_IMPORT_PATH : "${displayPowerPlugin}/lib/qt-6/qml" \
                  --prefix QML2_IMPORT_PATH : "${kirigami}/lib/qt-6/qml" \
                  --prefix QT_PLUGIN_PATH : "${qtMultimedia}/lib/qt-6/plugins" \
                  --prefix QT_PLUGIN_PATH : "${qtImageFormats}/lib/qt-6/plugins" \
                  --prefix PATH : "${libvaUtils}/bin" \
                  --prefix PATH : "${ffmpeg}/bin" \
                  --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
                  --set QS_LOG_FILE /dev/stderr \
                  --add-flags "--verbose"
              done
            '';
          };

          default = quickshell;
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          qualityTools = [
            pkgs.git
            pkgs.bash
            pkgs.qt6.qtdeclarative
            pkgs.clang-tools
            pkgs.nixfmt
          ];
          makeQualityApp = name: text: {
            type = "app";
            meta.description = "Quickshell project quality tool: ${name}";
            program = "${
              pkgs.writeShellApplication {
                inherit name;
                runtimeInputs = qualityTools;
                inherit text;
              }
            }/bin/${name}";
          };
          formatCheck = ''
            root=$(git rev-parse --show-toplevel)
            cd "$root"
            if (($#)); then files=("$@"); else
              mapfile -t files < <(git diff --name-only --diff-filter=ACMRT HEAD -- '*.qml' '*.cpp' '*.h' '*.js' 'flake.nix' ':!temp/**' ':!notes/**')
            fi
            status=0
            tmp=$(mktemp -d)
            trap 'rm -rf "$tmp"' EXIT
            for file in "''${files[@]}"; do
              [[ -f "$file" ]] || continue
              case "$file" in
                *.qml)
                  out="$tmp/$(basename "$file")"
                  if ! qmlformat "$file" > "$out"; then echo "format: qmlformat failed: $file" >&2; status=1
                  elif ! diff -u "$file" "$out" >/dev/null; then echo "format: $file is not qmlformat-clean" >&2; status=1; fi ;;
                *.cpp|*.h) clang-format --dry-run --Werror "$file" >/dev/null || { echo "format: $file is not clang-format-clean" >&2; status=1; } ;;
                flake.nix) nixfmt --check "$file" >/dev/null || { echo "format: $file is not nixfmt-clean" >&2; status=1; } ;;
              esac
            done
            exit "$status"
          '';
          format = ''
            root=$(git rev-parse --show-toplevel)
            cd "$root"
            if (($#)); then files=("$@"); else mapfile -t files < <(rg --files -g '*.qml' -g '*.cpp' -g '*.h' -g 'flake.nix' -g '!temp/**' -g '!notes/**' -g '!result/**'); fi
            for file in "''${files[@]}"; do
              [[ -f "$file" ]] || continue
              case "$file" in *.qml) qmlformat -i "$file" ;; *.cpp|*.h) clang-format -i "$file" ;; flake.nix) nixfmt "$file" ;; esac
            done
          '';
          lint = ''
            root=$(git rev-parse --show-toplevel)
            cd "$root"
            if (($#)); then files=("$@"); else mapfile -t files < <(git diff --name-only --diff-filter=ACMRT HEAD -- '*.qml' ':!temp/**' ':!notes/**'); fi
            status=0
            lintArgs=(--max-warnings -1 --import disable --missing-property disable --missing-type disable --unresolved-type disable --unqualified disable --access-singleton-via-object disable --signal-handler-parameters disable)
            for file in "''${files[@]}"; do [[ -f "$file" ]] || continue; qmllint "''${lintArgs[@]}" "$file" || status=1; done
            exit "$status"
          '';
          test = ''
            root=$(git rev-parse --show-toplevel)
            cd "$root"
            export QML2_IMPORT_PATH="${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.kdePackages.qtmultimedia}/lib/qt-6/qml:${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
            exec qmltestrunner "$@"
          '';
        in
        {
          format-check = makeQualityApp "quickshell-format-check" formatCheck;
          format = makeQualityApp "quickshell-format" format;
          lint = makeQualityApp "quickshell-lint" lint;
          test = makeQualityApp "quickshell-test" test;
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      nixosModules.default =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        let
          cfg = config.services.quickshell-greeter;
        in
        {
          options.services.quickshell-greeter = {
            enable = lib.mkEnableOption "Quickshell Greeter";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;
              description = "The wrapped quickshell package.";
            };
            configPackage = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.config;
              description = "The package containing greeter.qml and assets.";
            };
          };

          config = lib.mkIf cfg.enable {
            users.users.greeter.extraGroups = [
              "video"
              "input"
              "render"
              "seat"
            ];
            services.seatd.enable = true;

            services.greetd = {
              enable = true;
              settings = {
                terminal.vt = 1;
                default_session = {
                  command =
                    let
                      hyprlandConfig = pkgs.writeText "greeter-hyprland.conf" ''
                        exec-once = sh -c "stty -isig; ${cfg.package}/bin/quickshell --path ${cfg.configPackage}/greeter.qml; hyprctl dispatch exit"

                        misc {
                          disable_hyprland_logo = true
                          disable_splash_rendering = true
                          background_color = 0x000000
                        }

                        decoration {
                          rounding = 0
                        }

                        monitor = ,prefer,auto,1
                      '';
                    in
                    "${pkgs.dbus}/bin/dbus-run-session ${pkgs.hyprland}/bin/hyprland --config ${hyprlandConfig}";
                  user = "greeter";
                };
              };
            };

            environment.systemPackages = [
              pkgs.hyprland
              cfg.package
            ];
            environment.variables.WLR_NO_HARDWARE_CURSORS = "1";

            systemd.services.greetd.serviceConfig = {
              Type = "idle";
              StandardInput = "null";
              StandardOutput = "journal";
              StandardError = "journal";
              TTYReset = true;
              TTYVHangup = true;
              TTYVTDisallocate = true;
            };

            services.gnome.gnome-keyring.enable = true;
            security.pam.services.login.enableGnomeKeyring = true;
            security.pam.services.greetd.enableGnomeKeyring = true;
          };
        };

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          kirigami = pkgs.kdePackages.kirigami.unwrapped;
          qtMultimedia = pkgs.kdePackages.qtmultimedia;
        in
        {
          default = pkgs.mkShell {
            nativeBuildInputs = [
              quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
              pkgs.libcava
              pkgs.quickshell
              pkgs.upower
              pkgs.libnotify
              pkgs.wf-recorder
              pkgs.pulseaudio
              qtMultimedia
              pkgs.ffmpeg-full
              kirigami
              pkgs.kdePackages.sonnet
              pkgs.kdePackages.qtimageformats
              pkgs.kdePackages.kimageformats
              pkgs.libva-utils
              pkgs.clang-tools
              pkgs.nixfmt
            ];

            shellHook = ''
              export QML2_IMPORT_PATH="${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${qtMultimedia}/lib/qt-6/qml:${kirigami}/lib/qt-6/qml''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
            '';
          };
        }
      );
    };
}
