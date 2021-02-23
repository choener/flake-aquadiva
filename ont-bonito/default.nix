{ stdenv, fetchurl, lib, addOpenGLRunpath, patchelf, fetchFromGitHub, autoreconfHook
, python38, python38Packages, poetry, poetry2nix
, which, zlib, bzip2, lzma, cudatoolkit_10_2, cudnn_cudatoolkit_10_2, unzip
, linuxPackages
}:

let

  pP = python38Packages;
  build = pP.buildPythonPackage;
  cudatk = cudatoolkit_10_2;
  cudnn = cudnn_cudatoolkit_10_2;

  bonitosrc = rec {
    pname = "bonito";
    version = "0.3.5";
    src = fetchurl {
      url = "https://github.com/nanoporetech/bonito/archive/v${version}.tar.gz";
      sha256 = "EsCcwoNR5Y3oF4KjUGORO7qhkAFwdW6twPNFb36VvME=";
    };
  };

  model_r10v32 = fetchurl {
    url = "https://nanoporetech.box.com/shared/static/yesf11tisfrncmod5hj2xtx9kbdveuqt.zip";
    sha256 = "5dH9TKXGLkS3NVc+J9z3BTKWQYaHVN4DzSaKbotUv00=";
  };

  parasail = stdenv.mkDerivation rec {
    name = "parasail";
    version = "2.4.3";
    src = fetchFromGitHub {
      owner = "jeffdaily";
      repo = "parasail";
      rev = "v2.4.3";
      sha256 = "Mkv39Zd4o5V5TPQxuPuMXyfnDXA54rlWILXe6PJmrVI=";
    };
    nativeBuildInputs = [ autoreconfHook ];
    enableParallelBuilding = true;
  };

in

# TODO download model files and provide to bonito
poetry2nix.mkPoetryApplication {
  projectDir = ./.;
  src = bonitosrc.src;
  # do not download model files here
  preBuild = ''
    substituteInPlace setup.py \
      --replace "'install': download_latest_model," ""
  '';
  preFixup = ''
    makeWrapperArgs+="--prefix PATH : ${lib.makeLibraryPath [ parasail ]} "
    makeWrapperArgs+="--prefix LD_LIBRARY_PATH : '/run/opengl-driver/lib' "
  '';
  postFixup = ''
    mkdir $out/models
    unzip ${model_r10v32} -d $out/models
  '';
  python = pP.python;
  nativeBuildInputs = [ poetry unzip ];

  overrides = poetry2nix.overrides.withDefaults (self: super: {
    mappy = super.mappy.overridePythonAttrs (old: { propagatedBuildInputs = old.propagatedBuildInputs ++ [ zlib ]; });
    # TODO might have to set a dynamic lib path to parasail C
    parasail = super.parasail.overridePythonAttrs (old: {
      PARASAIL_SKIP_BUILD = true;
      propagatedBuildInputs = old.propagatedBuildInputs ++ [ parasail ];
      doCheck = false;
    }); #parasail
    torch = super.torch.overridePythonAttrs (old: rec {
      propagatedBuildInputs = old.propagatedBuildInputs ++ [ cudatk ];
      postFixup = ''
        addOpenGLRunpath $out/lib/python3.8/site-packages/torch/lib/libcaffe2_nvrtc.so
      '';
      nativeBuildInputs = old.nativeBuildInputs ++ [ addOpenGLRunpath ];
      autoPatchelfIgnoreMissingDeps = true;
      enableParallelBuilding = true;
    }); #torch
    cupy-cuda102 = super.cupy-cuda102.overridePythonAttrs (old: rec {
      propagatedBuildInputs = old.propagatedBuildInputs ++ [ cudatk cudnn ];
      nativeBuildInputs = old.nativeBuildInputs ++ [ addOpenGLRunpath ];
      postFixup = ''
        addOpenGLRunpath $out/lib/python3.8/site-packages/cupy/_util.cpython-38-x86_64-linux-gnu.so
      '';
      autoPatchelfIgnoreMissingDeps = true;
    }); #cupy
  });
}

