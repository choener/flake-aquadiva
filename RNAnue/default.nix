{ stdenv, cmake, boost172, range-v3, pkg-config, sdsl-lite, SeqAn3, ... }: src: let

in stdenv.mkDerivation {
  name = "RNAnue";
  nativeBuildInputs = [ cmake boost172 range-v3 sdsl-lite SeqAn3 ];
  buildInputs = [ ];
  inherit src;

  enableParallelBuilding = true;

  patchPhase = ''
    cd include
    sed -i 's/#include <chrono>/#include <chrono>\n#include <memory>/' Helper.hpp
    cd ..
  '';

  configurePhase = ''
    mkdir bin
    cd bin
    cmake ..
  '';

  buildPhase = ''
    make -j
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share
    cp RNAnue $out/bin
    cp ../build/params.cfg $out/share
  '';
}
