{ pkgs ? import <nixpkgs> {} }:
with pkgs;

 mkShell {
    # nativeBuildInputs is usually what you want -- tools you need to run
    nativeBuildInputs = with pkgs.buildPackages; [ go ];
    buildInputs = [ stdenv glibc.static ];
    CFLAGS="-I${pkgs.glibc.dev}/include";
    LDFLAGS="-L/nix/store/343zalci1q1x74w74r4x8444fibcclx4-valhalla-go/lib";
}
