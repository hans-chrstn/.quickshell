{ pkgs }:
pkgs.stdenv.mkDerivation {
  pname = "dpms-observer-prototype";
  version = "0.1";
  src = ./.;
  nativeBuildInputs = [ pkgs.pkg-config pkgs.wayland-scanner ];
  buildInputs = [ pkgs.wayland ];
  buildPhase = ''
    protocol=${pkgs.wlr-protocols}/share/wlr-protocols/unstable/wlr-output-power-management-unstable-v1.xml
    wayland-scanner client-header "$protocol" power-client.h
    wayland-scanner private-code "$protocol" power-protocol.c
    $CC -c power-protocol.c $(pkg-config --cflags wayland-client)
    $CXX -std=c++20 -Wall -Wextra -Werror main.cpp power-protocol.o \
      $(pkg-config --cflags --libs wayland-client) -o dpms-observer
  '';
  installPhase = ''
    install -Dm755 dpms-observer $out/bin/dpms-observer
  '';
}
