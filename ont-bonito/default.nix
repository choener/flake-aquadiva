{ stdenv, fetchurl, lib, addOpenGLRunpath, patchelf
, python3, python3Packages, poetry2nix
, which, zlib, bzip2, lzma, cudatoolkit_10_0
}:

let

  pP = python3Packages;
  build = pP.buildPythonPackage;
  cudatk = cudatoolkit_10_0;

  bonitosrc = rec {
    pname = "bonito";
    version = "0.3.5";
    src = fetchurl {
      url = "https://github.com/nanoporetech/bonito/archive/v${version}.tar.gz";
      sha256 = "EsCcwoNR5Y3oF4KjUGORO7qhkAFwdW6twPNFb36VvME=";
    };
  };

in

poetry2nix.mkPoetryApplication {
  projectDir = ./.;
  src = bonitosrc.src;
  unpackPhase = ''
    ls -alh $src
    tar xfz $src
    ls -alh
    cd bonito-0.3.5
    ls -alh
  '';
  python = pP.python;
  overrides = poetry2nix.overrides.withDefaults (self: super: {
    mappy = super.mappy.overridePythonAttrs (old: { propagatedBuildInputs = old.propagatedBuildInputs ++ [ zlib ]; });
    #torch = super.torch.overridePythonAttrs (old: rec {
    #  propagatedBuildInputs = old.propagatedBuildInputs ++ [ cudatk ];
    #  postFixup = ''
    #    addOpenGLRunpath $out/lib/python3.6/site-packages/torch/lib/libcaffe2_nvrtc.so
    #  '';
    #  glPhase = ''
    #    echo "XXX $out ZZZ"
    #    #addOpenGLRunpath $out/lib/python3.6/site-packages/torch/lib/libcaffe2_nvrtc.so
    #  '';
    #  nativeBuildInputs = old.nativeBuildInputs ++ [ addOpenGLRunpath ];
    #  autoPatchelfIgnoreMissingDeps = true;
    #});
  });
}

