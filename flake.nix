{
  description = "Repository of software to support AquaDiva";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: let

    # each system
    eachSystem = system: let

      pkgs = import nixpkgs { inherit system; };
      # fhs with things we need
      fhs = pkgs.buildFHSUserEnv {
        name = "fhs";
        targetPkgs = p: [ p.jdk14 ];
      };

    in rec {
      devShell = pkgs.stdenv.mkDerivation {
        name = "AquaDiva";
        nativeBuildInputs = [ fhs ];
        shellHook = ''
          ${fhs}/bin/AquaDivaFHS
        '';
      }; # devShell
      apps.fhs = { type = "app"; program = "${fhs}/bin/fhs"; };
      # by default, we get the @fhs@ environment to play around in.
      defaultApp = apps.fhs;
    }; # eachSystem

  in
    flake-utils.lib.eachDefaultSystem eachSystem;
}
