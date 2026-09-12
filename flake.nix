{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    quickshell,
    self,
  }: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
      qtMultimedia = pkgs.kdePackages.qtmultimedia;
      qtImageFormats = pkgs.kdePackages.qtimageformats;
      libvaUtils = pkgs.libva-utils;
      kirigami = pkgs.kdePackages.kirigami.unwrapped;
      qmlQuickshell = quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in rec {
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
        paths = [qmlQuickshell];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          for bin in $out/bin/*; do
            wrapProgram "$bin" \
              --prefix QML2_IMPORT_PATH : "${qtMultimedia}/lib/qt-6/qml" \
              --prefix QML2_IMPORT_PATH : "${kirigami}/lib/qt-6/qml" \
              --prefix QT_PLUGIN_PATH : "${qtMultimedia}/lib/qt-6/plugins" \
              --prefix QT_PLUGIN_PATH : "${qtImageFormats}/lib/qt-6/plugins" \
              --prefix PATH : "${libvaUtils}/bin" \
              --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
              --set QS_LOG_FILE /dev/stderr \
              --add-flags "--verbose"
          done
        '';
      };

      default = quickshell;
    });

    nixosModules.default = {
      pkgs,
      lib,
      config,
      ...
    }: let
      cfg = config.services.quickshell-greeter;
    in {
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
        users.users.greeter.extraGroups = ["video" "input" "render" "seat"];
        services.seatd.enable = true;

        services.greetd = {
          enable = true;
          settings = {
            terminal.vt = 1;
            default_session = {
              command = let
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
              in "${pkgs.dbus}/bin/dbus-run-session ${pkgs.hyprland}/bin/hyprland --config ${hyprlandConfig}";
              user = "greeter";
            };
          };
        };

        environment.systemPackages = [pkgs.hyprland cfg.package];
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

    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
      kirigami = pkgs.kdePackages.kirigami.unwrapped;
      qtMultimedia = pkgs.kdePackages.qtmultimedia;
    in {
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
        ];

        shellHook = ''
          export QML2_IMPORT_PATH="${qtMultimedia}/lib/qt-6/qml:${kirigami}/lib/qt-6/qml:$QML2_IMPORT_PATH"
        '';
      };
    });
  };
}
