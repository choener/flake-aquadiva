{ stdenv, cmake, gtest, ... }: src: let

in stdenv.mkDerivation {
  name = "sdsl-lite";
  inherit src;

  buildInputs = [ cmake ];

  configurePhase = ''
    cp ${./CMakeLists.txt} CMakeLists.txt
    mkdir -p $out
    mkdir -p build_
    cd build_
    cmake -DCMAKE_INSTALL_PREFIX=$out ..
  '';

  installPhase = ''
    make
    make install
    cd ..
    cp -r include $out/
  '';
    #cp -r include $out
    #cp -r build_system $out

}


