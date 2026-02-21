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
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        rocmSupport = true;
      };
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      nativeBuildInputs = [
        qml-niri.packages.${system}.quickshell
        pkgs.quickshell
        pkgs.upower
        pkgs.libnotify
        pkgs.wf-recorder
        pkgs.swww
      ];
    };
  };
}
