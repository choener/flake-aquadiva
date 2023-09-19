{ stdenv, fetchurl, zlib, pkg-config, htslib, ncurses, ... }: let

in stdenv.mkDerivation {
  name = "segemehl";
  nativeBuildInputs = [ pkg-config zlib htslib ncurses ];
  buildInputs = [ ];
  src = fetchurl {
    url = "http://legacy.bioinf.uni-leipzig.de/Software/segemehl/downloads/segemehl-0.3.4.tar.gz";
    sha256 = "sha256-5DNvA9DRUSbbscY2jH6AQhsMc1T0prSS1U19FM9af1E=";
  };

  enableParallelBuilding = true;

  buildPhase = ''
    make -j all
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp segemehl.x haarz.x $out/bin
  '';

}

