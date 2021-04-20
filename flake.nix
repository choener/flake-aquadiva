{
  description = "Repository of software to support AquaDiva";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
    flake-utils.url = "github:numtide/flake-utils";
    nextflow-src = {
      url = "https://github.com/nextflow-io/nextflow/archive/v20.10.0.tar.gz";
      flake = false;
    };
    poseidon-src = {
      url = "https://github.com/hoelzer/poseidon/archive/v1.0.1.tar.gz";
      flake = false;
    };
    viennarna-src = {
      url = "https://www.tbi.univie.ac.at/RNA/download/sourcecode/2_4_x/ViennaRNA-2.4.17.tar.gz";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils
            , nextflow-src, poseidon-src, viennarna-src }: let

    # each system
    eachSystem = system: let
      config = { allowUnfree = true;};
      pkgs = import nixpkgs {
        inherit system;
        inherit config;
        overlays = [ self.overlay ];
      };
      # fhs with things we need
      fhs = pkgs.buildFHSUserEnv {
        name = "fhs";
        targetPkgs = p: [ p.jdk14 nextflow poseidon bonito p.ViennaRNA ];
      };
      ## TODO nextflow should actually be embedded within an FHS
      nextflow = pkgs.stdenv.mkDerivation {
        name = "nextflow";
        src = nextflow-src;
        configurePhase = "true";
        buildPhase = "true";
        installPhase = ''
          mkdir -p $out/bin
          cp -r nextflow modules $out
          cd $out/bin
          ln -s ../nextflow
        '';
      };
      # TODO should depend on nextflow
      poseidon = pkgs.stdenv.mkDerivation {
        name = "poseidon";
        src = poseidon-src;
        configurePhase = "true";
        buildPhase = "true";
        installPhase = ''
          mkdir -p $out/bin
          rm .gitignore
          cp -r . $out
          cd $out/bin
          ln -s ../poseidon.nf poseidon
        '';
      };
      bonito = pkgs.callPackage ./ont-bonito {};

    in rec {
      devShell = pkgs.stdenv.mkDerivation {
        name = "AquaDiva";
        nativeBuildInputs = [ fhs ];
        shellHook = ''
          ${fhs}/bin/fhs
        '';
      }; # devShell
      apps.fhs = { type = "app"; program = "${fhs}/bin/fhs"; };
      apps.nextflow = { type = "app"; program = "${nextflow}/bin/nextflow"; };
      # by default, we get the @fhs@ environment to play around in.
      defaultApp = apps.fhs;
      packages = { inherit fhs;
                   inherit nextflow poseidon bonito; inherit (pkgs) ViennaRNA; };
    }; # eachSystem

  in
    flake-utils.lib.eachDefaultSystem eachSystem // { overlay = final: prev: {
      ViennaRNA = final.callPackage ./viennarna { inherit viennarna-src; };
    };};
}
