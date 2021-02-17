{
  description = "Repository of software to support AquaDiva";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
    flake-utils.url = "github:numtide/flake-utils";
    nextflow-src = {
      url = "https://github.com/nextflow-io/nextflow/archive/v20.10.0.tar.gz";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, nextflow-src }: let

    # each system
    eachSystem = system: let

      pkgs = import nixpkgs { inherit system; };
      # fhs with things we need
      fhs = pkgs.buildFHSUserEnv {
        name = "fhs";
        targetPkgs = p: [ p.jdk14 nextflow ];
      };
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
      packages = { inherit nextflow; inherit fhs; };
    }; # eachSystem

  in
    flake-utils.lib.eachDefaultSystem eachSystem;
}
