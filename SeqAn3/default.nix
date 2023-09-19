{ stdenv, cmake, range-v3, sdsl-lite, ... }: src: let

in stdenv.mkDerivation {
  name = "SeqAn3";
  nativeBuildInputs = [ cmake sdsl-lite range-v3 ];
  buildInputs = [ ];
  inherit src;

  cmakeFlags = [];

  configurePhase = ''
    mkdir -p $out
    mkdir -p build_
    cd build_
    cmake -DCMAKE_INSTALL_PREFIX=$out ..
  '';

  installPhase = ''
    make install
  '';

}

