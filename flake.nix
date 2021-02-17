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
  };

  outputs = { self, nixpkgs, flake-utils
            , nextflow-src, poseidon-src }: let

    # each system
    eachSystem = system: let

      pkgs = import nixpkgs { inherit system; };
      # fhs with things we need
      fhs = pkgs.buildFHSUserEnv {
        name = "fhs";
        targetPkgs = p: [ p.jdk14 nextflow poseidon ];
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
      packages = { inherit nextflow; inherit poseidon; inherit fhs; };
    }; # eachSystem

  in
    flake-utils.lib.eachDefaultSystem eachSystem;
}
