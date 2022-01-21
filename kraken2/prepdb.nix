# This script prepares different databases for use with kraken2. Thi interpreter is @bash@.

# TODO have a number of selectable data bases
# TODO write into target directory, if directory empty
# TODO consider error checking / checksumming based on checksums for known DBs

{writeShellScriptBin, kraken2, coreutils}:

writeShellScriptBin "prepdb" ''
  echo "Kraken2 script preparation";
  if [ "$#" -ne 2 ]; then
    echo "Require exactly two arguments: (i) target directory & (ii) DB / url"
    exit 1
  fi
  # TODO better to just check individual checkpoints, instead of single stop/go
  #if [ -z "$(ls -A $1)" ]; then
  #  echo "Target directory empty ... preparing"
  #else
  #  echo "Target directory $1 not empty"
  #  # TODO checksumming?
  #  exit 1
  #fi

  case $2 in
    GVD)
      echo "Preparing gut virus database"
      ;;
    *)
      echo "Preparing generic database"
      ;;
  esac

  # TODO run kraken2
  T=$(${coreutils}/bin/nproc)
  echo "using $T cpu threads for building DB $1"
  # TODO this is for testing right now
  echo "downloading taxonomy"
  ${kraken2}/bin/kraken2-build --threads $T --download-taxonomy --db $1
  echo "downloading library viral"
  echo `which rsync`
  ${kraken2}/bin/kraken2-build --threads $T --download-library viral --db $1
  echo "building DB"
  ${kraken2}/bin/kraken2-build --threads $T --build --db $1
''

