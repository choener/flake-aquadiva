{
  description = "Repository of software to support AquaDiva";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-23.05;
    flake-utils.url = github:numtide/flake-utils;
    devshell.url = github:numtide/devshell;
    #
    #nextflow = { url = github:nextflow-io/nextflow/archive/v20.10.0.tar.gz; flake = false; };
    #poseidon = { url = github:hoelzer/poseidon/archive/v1.0.1.tar.gz; flake = false; };
    RNAnue = { url = github:Ibvt/RNAnue/v0.1.1; flake = false; };
    SeqAn3 = { url = github:seqan/seqan3/3.0.2; flake = false; };
    sdsl-lite = { url = github:xxsds/sdsl-lite/v3.0.3; flake = false; };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }: let

    # each system
    eachSystem = system: let
      config = { allowUnfree = true;};
      pkgs = import nixpkgs {
        inherit system;
        inherit config;
        overlays = [ self.overlay inputs.devshell.overlays.default ];
      };
      # fhs with things we need
      #fhs = pkgs.buildFHSUserEnv {
      #  name = "fhs";
      #  targetPkgs = p: [ nextflow poseidon bonito p.ViennaRNA ];
      #};
      ### TODO nextflow should actually be embedded within an FHS
      #nextflow = pkgs.stdenv.mkDerivation {
      #  name = "nextflow";
      #  src = inputs.nextflow;
      #  configurePhase = "true";
      #  buildPhase = "true";
      #  installPhase = ''
      #    mkdir -p $out/bin
      #    cp -r nextflow modules $out
      #    cd $out/bin
      #    ln -s ../nextflow
      #  '';
      #};
      ## TODO should depend on nextflow
      #poseidon = pkgs.stdenv.mkDerivation {
      #  name = "poseidon";
      #  src = inputs.poseidon;
      #  configurePhase = "true";
      #  buildPhase = "true";
      #  installPhase = ''
      #    mkdir -p $out/bin
      #    rm .gitignore
      #    cp -r . $out
      #    cd $out/bin
      #    ln -s ../poseidon.nf poseidon
      #  '';
      #};
      bonito = pkgs.callPackage ./ont-bonito {};

    in rec {
      #devShell = pkgs.stdenv.mkDerivation {
      #  name = "AquaDiva";
      #  nativeBuildInputs = [ fhs ];
      #  shellHook = ''
      #    ${fhs}/bin/fhs
      #  '';
      #}; # devShell
      devShell = pkgs.devshell.mkShell {
        devshell.packages = with pkgs; [ RNAnue ViennaRNA ];
      };
      devShells."virusdb" = pkgs.stdenv.mkDerivation {
        nativeBuildInputs = with pkgs; [ kraken2 prepkraken2db ];
        name = "VirusDB";
      };
      #apps.fhs = { type = "app"; program = "${fhs}/bin/fhs"; };
      #apps.nextflow = { type = "app"; program = "${nextflow}/bin/nextflow"; };
      apps.RNAfold = { type = "app"; program = "${pkgs.ViennaRNA}/bin/RNAfold"; };
      # by default, we get the @fhs@ environment to play around in.
      #defaultApp = apps.fhs;
      packages = {
        inherit (pkgs) ViennaRNA;
        inherit (pkgs) kraken2 prepkraken2db;
        inherit (pkgs) RNAnue;
        inherit (pkgs) SeqAn3;
        inherit (pkgs) sdsl-lite;
        inherit (pkgs) segemehl;
        dockerRNAnue = pkgs.dockerTools.buildImage {
          # The params.cfg file for RNAnue is under /share
          name = "RNAnue with ViennaRNA";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ pkgs.RNAnue pkgs.ViennaRNA pkgs.segemehl ];
            pathsToLink = [ "/bin" "/share" ];
          };
          config.Cmd = [ "/bin/RNAnue" ];
        };
      }; # packages
    }; # eachSystem 

  in
    flake-utils.lib.eachDefaultSystem eachSystem // { overlay = final: prev: {
      ViennaRNA = final.callPackage ./viennarna {};
      kraken2 = final.callPackage ./kraken2 {};
      prepkraken2db = final.callPackage ./kraken2/prepdb.nix {};
      RNAnue = (final.callPackage ./RNAnue {}) inputs.RNAnue;
      SeqAn3 = (final.callPackage ./SeqAn3 {}) inputs.SeqAn3;
      sdsl-lite = (final.callPackage ./sdsl-lite {}) inputs.sdsl-lite;
      segemehl = final.callPackage ./segemehl {};
    };};
}

