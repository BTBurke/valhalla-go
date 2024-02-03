{ lib
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
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "valhalla";
  version = "refs/heads/master";

  src = fetchFromGitHub {
    owner = "valhalla";
    repo = "valhalla";
    rev = finalAttrs.version;
    sha256 = "v6ci4O7Au6A3MdfxqmT0gBQThodBpAXvnRiyS7Dv2ac=";
    fetchSubmodules = true;
  };

  patches = [
    # Fix build
    #(fetchpatch {
    #  url = "https://github.com/valhalla/valhalla/commit/e4845b68e8ef8de9eabb359b23bf34c879e21f2b.patch";
    #  hash = "sha256-xCufmXHGj1JxaMwm64JT9FPY+o0+x4glfJSYLdvHI8U=";
    # })
  ];

  postPatch = ''
    substituteInPlace src/bindings/python/CMakeLists.txt \
      --replace "\''${Python_SITEARCH}" "${placeholder "out"}/${python3.sitePackages}"
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  cmakeFlags = [
    "-DENABLE_TESTS=OFF"
    "-DENABLE_BENCHMARKS=OFF"
    "-DENABLE_CCACHE=OFF"
    "-DENABLE_SINGLE_FILES_WERROR=OFF"
    "-DCMAKE_C_COMPILER=gcc"
    "-DBUILD_SHARED_LIBS=OFF"
    "-DENABLE_PYTHON_BINDINGS=OFF"
    "-DENABLE_TOOLS=OFF"
    "-DENABLE_SERVICES=OFF"
    "-DENABLE_HTTP=OFF"
    "-DENABLE_CCACHE=OFF"
    "-DENABLE_DATA_TOOLS=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  env.NIX_CFLAGS_COMPILE = toString [
    # Needed for date submodule with GCC 12 https://github.com/HowardHinnant/date/issues/750
    "-Wno-error=stringop-overflow"
  ];

  buildInputs = [
    boost
    curl
    geos
    libspatialite
    luajit
    prime-server
    protobuf
    python3
    sqlite
    zeromq
    zlib
  ];

  postFixup = ''
    substituteInPlace "$out"/lib/pkgconfig/libvalhalla.pc \
      --replace '=''${prefix}//' '=/' \
      --replace '=''${exec_prefix}//' '=/'
  '';

  passthru.tests = {
    pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  postInstall = ''
    cp -r $out/include/valhalla/third_party/* $out/include/
  '';


  meta = with lib; {
    changelog = "https://github.com/valhalla/valhalla/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    description = "Open Source Routing Engine for OpenStreetMap";
    homepage = "https://valhalla.readthedocs.io/";
    license = licenses.mit;
    maintainers = [ maintainers.Thra11 ];
    platforms = platforms.linux;
  };
})
