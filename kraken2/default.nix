{ lib, stdenv, fetchurl, fetchFromGitHub, bash, perl }:

stdenv.mkDerivation rec {
  name = "kraken2";
  version = "2.0.8-beta";
  src = fetchFromGitHub {
    owner = "DerrickWood";
    repo = "kraken2";
    rev = "v2.1.2";
    sha256 = "sha256-Tuqew4ZSerKukTbCiUN6A/NAHcCm6Is8tFC8RgOtht4=";
  };
  nativeBuildInputs = [ perl ];

  enableParallelBuilding = true;

  postPatch = ''
    for f in install_kraken2.sh scripts/16S_gg_installation.sh scripts/16S_rdp_installation.sh scripts/16S_silva_installation.sh scripts/add_to_library.sh scripts/build_kraken2_db.sh scripts/clean_db.sh scripts/download_genomic_library.sh scripts/download_taxonomy.sh scripts/mask_low_complexity.sh scripts/standard_installation.sh
    do
      substituteInPlace $f --replace /bin/bash ${bash}/bin/bash
    done
  '';

  buildPhase = ''
    mkdir -p $out/bin
    ./install_kraken2.sh $out/bin
  '';

  installPhase = "return 0";

  meta = {
    description = "Kraken 2: Taxonomic Sequence Classification System";
    longDescription = ''
      Kraken is a taxonomic sequence classifier that assigns taxonomic labels to DNA sequences.
      Kraken examines the k-mers within a query sequence and uses the information within those
      k-mers to query a database. That database maps k-mers to the lowest common ancestor (LCA) of
      all genomes known to contain a given k-mer.
    '';
    homepage = https://ccb.jhu.edu/software/kraken2/;
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}

