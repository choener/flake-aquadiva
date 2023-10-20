{ lib, stdenv, fetchurl , perl }:

stdenv.mkDerivation rec {
  name = "MUMmer";
  version = "v4.0.0rc1";
  src = fetchurl {
    url = https://github.com/mummer4/mummer/releases/download/v4.0.0rc1/mummer-4.0.0rc1.tar.gz;
    sha256 = "sha256-hQBq2y1lOcL3OMPjuxS1i7b2LNbGyl7eiEqHrnbgfR0=";
 };
  nativeBuildInputs = [ perl ];

  enableParallelBuilding = true;

  meta = {
    description = "";
    longDescription = ''
    '';
    homepage = https://mummer4.github.io/index.html;
    license = "";
    maintainers = [  ];
    platforms = lib.platforms.linux;
  };
}

