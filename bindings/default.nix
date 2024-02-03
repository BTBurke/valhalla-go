{ nixpkgs ? import <nixpkgs> {}
, lib
, stdenv
, fetchFromGitHub
, fetchpatch
, cmake
, pkg-config
, boost
, curl
, geos
, libspatialite
, luajit
, prime-server
, protobuf
, python3
, sqlite
, zeromq
, zlib
, testers
, abseil-cpp
, gtest

, ...
}:

with nixpkgs;

let
  valhallaCustom = (import ./valhalla) { inherit lib stdenv fetchFromGitHub fetchpatch cmake pkg-config boost curl geos libspatialite luajit prime-server protobuf python3 sqlite zeromq zlib testers; };
in stdenv.mkDerivation rec {
  name = "valhallago";
  src = ./.;

  buildInputs = [
    boost179
    valhallaCustom
    zlib.static
    protobuf
  ];

  buildPhase = ''
    g++ \
      valhalla_go.cpp \
      -fPIC \
      -shared \
      -o libvalhallago.so \
      -Wl,-Bstatic \
      -lvalhalla \
      -lz \
      -Wl,-Bdynamic \
      -lprotobuf \
      -lpthread
  '';

  installPhase = ''
    mkdir -p $out/lib
    cp libvalhallago.so $out/lib
  '';
}
