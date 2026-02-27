{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qml-niri = {
      url = "github:imiric/qml-niri/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
    };
  };

  outputs = {
    nixpkgs,
    quickshell,
    self,
    qml-niri,
  }: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
      qtMultimedia = pkgs.kdePackages.qtmultimedia;
      qtImageFormats = pkgs.kdePackages.qtimageformats;
      kirigami = pkgs.kdePackages.kirigami.unwrapped;
      qmlNiri = qml-niri.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;
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
        paths = [qmlNiri];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          for bin in $out/bin/*; do
            wrapProgram "$bin" \
              --prefix QML2_IMPORT_PATH : "${qtMultimedia}/lib/qt-6/qml" \
              --prefix QML2_IMPORT_PATH : "${kirigami}/lib/qt-6/qml" \
              --prefix QT_PLUGIN_PATH : "${qtMultimedia}/lib/qt-6/plugins" \
              --prefix QT_PLUGIN_PATH : "${qtImageFormats}/lib/qt-6/plugins" \
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
                niriConfig = pkgs.writeText "greeter-niri.kdl" ''
                  spawn-at-startup "${cfg.package}/bin/quickshell" "--path" "${cfg.configPackage}/greeter.qml"
                  hotkey-overlay {
                    skip-at-startup
                  }
                  layout {
                    background-color "#000000"
                  }
                  window-rule {
                    geometry-corner-radius 0
                    draw-border-with-background false
                  }
                '';
              in "${pkgs.dbus}/bin/dbus-run-session ${pkgs.niri}/bin/niri -c ${niriConfig}";
              user = "greeter";
            };
          };
        };

        environment.systemPackages = [pkgs.niri cfg.package];
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
          qml-niri.packages.${pkgs.stdenv.hostPlatform.system}.quickshell
          pkgs.libcava
          pkgs.quickshell
          pkgs.upower
          pkgs.libnotify
          pkgs.wf-recorder
          pkgs.swww
          pkgs.kdePackages.qtmultimedia
          kirigami
          pkgs.kdePackages.sonnet
          pkgs.kdePackages.qtimageformats
          pkgs.kdePackages.kimageformats
        ];

        shellHook = ''
          export QML2_IMPORT_PATH="${qtMultimedia}/lib/qt-6/qml:${kirigami}/lib/qt-6/qml:$QML2_IMPORT_PATH"
        '';
      };
    });
  };
}
