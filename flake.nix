{
  description = "Nacre, a Pleamar-powered desktop shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pleamar.url = "github:k4ditano/pleamar";
    pleamar.inputs.nixpkgs.follows = "nixpkgs";
    pleamarWm.url = "github:k4ditano/pleamar-wm";
    pleamarWm.inputs.nixpkgs.follows = "nixpkgs";
    pleamarWm.inputs.pleamar.follows = "pleamar";
  };

  outputs =
    {
      self,
      nixpkgs,
      pleamar,
      pleamarWm,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = function: nixpkgs.lib.genAttrs systems function;
      checkTool =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.writeShellApplication {
          name = "nacre-check";
          runtimeInputs = [
            pleamar.packages.${system}.default
            pkgs.luau-lsp
            pkgs.findutils
            pkgs.gnugrep
            pkgs.ripgrep
          ];
          text = ''
            project_root="''${1:-.}"
            checked_scenes=0
            checked_logic=0
            definitions_dir="$(mktemp -d)"
            trap 'rm -r "$definitions_dir"' EXIT
            pleamar --luau-types > "$definitions_dir/base.luau"

            production_paths=("$project_root/Nacre.plm" "$project_root/Nacre.luau" "$project_root/logic" "$project_root/scenes")
            if rg -n '(/home/[[:alnum:]_.-]+|DP-[0-9]+|hyprctl|audio\.sink)' "''${production_paths[@]}" --glob '*.plm' --glob '*.luau'; then
              echo "Production source contains a machine- or compositor-specific dependency" >&2
              exit 1
            fi
            if rg -n '^[[:space:]]*(//|--)' "''${production_paths[@]}" --glob '*.plm' --glob '*.luau'; then
              echo "Production Pleamar and Luau source must not contain code comments" >&2
              exit 1
            fi

            if [ -f "$project_root/Nacre.plm" ]; then
              pleamar --check "$project_root/Nacre.plm"
              pleamar --luau-types "$project_root/Nacre.plm" > "$definitions_dir/nacre.luau"
              checked_scenes=$((checked_scenes + 1))
            fi

            for source_dir in "$project_root/scenes" "$project_root/tests"; do
              if [ ! -d "$source_dir" ]; then
                continue
              fi

              while IFS= read -r -d "" scene_file; do
                if ! grep -Eq '^[[:space:]]*scene[[:space:]]+[[:alpha:]_]' "$scene_file"; then
                  continue
                fi

                pleamar --check "$scene_file"
                checked_scenes=$((checked_scenes + 1))
              done < <(find "$source_dir" -type f -name '*.plm' -print0)
            done

            if [ -f "$project_root/Nacre.luau" ]; then
              definitions="$definitions_dir/base.luau"
              if [ -f "$definitions_dir/nacre.luau" ]; then
                definitions="$definitions_dir/nacre.luau"
              fi
              luau-lsp analyze --platform standard --definitions="@pleamar=$definitions" "$project_root/Nacre.luau"
              checked_logic=$((checked_logic + 1))
            fi

            for source_dir in "$project_root/logic" "$project_root/scenes" "$project_root/tests"; do
              if [ ! -d "$source_dir" ]; then
                continue
              fi

              while IFS= read -r -d "" logic_file; do
                scene_file="''${logic_file%.luau}.plm"
                definitions="$definitions_dir/base.luau"
                if [ -f "$scene_file" ] && grep -Eq '^[[:space:]]*scene[[:space:]]+[[:alpha:]_]' "$scene_file"; then
                  definitions="$definitions_dir/scene-$checked_logic.luau"
                  pleamar --luau-types "$scene_file" > "$definitions"
                elif [ -f "$definitions_dir/nacre.luau" ]; then
                  definitions="$definitions_dir/nacre.luau"
                fi
                luau-lsp analyze --platform standard --definitions="@pleamar=$definitions" "$logic_file"
                checked_logic=$((checked_logic + 1))
              done < <(find "$source_dir" -type f -name '*.luau' -print0)
            done

            if [ "$checked_scenes" -eq 0 ]; then
              echo "No Pleamar scenes found to check" >&2
              exit 1
            fi

            echo "Nacre checks passed: $checked_scenes scene(s), $checked_logic Luau file(s)"
          '';
        };
    in
    {
      packages = forAllSystems (system: {
        pleamar = pleamar.packages.${system}.default;
        pleamar-wm = pleamarWm.packages.${system}.default;
        default = self.packages.${system}.pleamar;
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.pleamar}/bin/pleamar";
          meta.description = "Run the pinned Pleamar runtime";
        };
        pleamar = {
          type = "app";
          program = "${self.packages.${system}.pleamar}/bin/pleamar";
          meta.description = "Run the pinned Pleamar runtime";
        };
        pleamar-wm = {
          type = "app";
          program = "${self.packages.${system}.pleamar-wm}/bin/pleamar-wm";
          meta.description = "Run the pinned pleamar-wm";
        };
        check = {
          type = "app";
          program = "${checkTool system}/bin/nacre-check";
          meta.description = "Check Nacre scenes and Luau logic";
        };
      });

      checks = forAllSystems (system: {
        project = nixpkgs.legacyPackages.${system}.runCommand "nacre-project-check" { } ''
          ${checkTool system}/bin/nacre-check ${self}
          touch "$out"
        '';
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
