{
  description = "Repository of software to support AquaDiva";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-23.05;
    flake-utils.url = github:numtide/flake-utils;
    devshell.url = github:numtide/devshell;
    #
    #nextflow = { url = github:nextflow-io/nextflow/archive/v20.10.0.tar.gz; flake = false; };
    #poseidon = { url = github:hoelzer/poseidon/archive/v1.0.1.tar.gz; flake = false; };
    RNAnue = { url = github:Ibvt/RNAnue/; flake = false; };
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
      bonito = pkgs.callPackage ./ont-bonito {};

    in rec {
      # Currently for debugging RNAnue.
      devShell = pkgs.devshell.mkShell {
        devshell.packages = with pkgs; RNAnue.nativeBuildInputs ++ [
          # RNAnue 
          ViennaRNA segemehl
        ];
        env = [
          { name = "CPPTOOLS"; value = "${pkgs.vscode-extensions.ms-vscode.cpptools}"; }
          { name = "LLDB"; value = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb"; }
        ];
      };
      devShells."virusdb" = pkgs.stdenv.mkDerivation {
        nativeBuildInputs = with pkgs; [ kraken2 prepkraken2db ];
        name = "VirusDB";
      };
      apps.RNAfold = { type = "app"; program = "${pkgs.ViennaRNA}/bin/RNAfold"; };
      packages = {
        inherit (pkgs) ViennaRNA;
        inherit (pkgs) kraken2 prepkraken2db;
        inherit (pkgs) RNAnue;
        inherit (pkgs) SeqAn3;
        inherit (pkgs) sdsl-lite;
        inherit (pkgs) segemehl;
        inherit (pkgs) mummer;
        dockerRNAnue = pkgs.dockerTools.buildImage {
          # The params.cfg file for RNAnue is under /share
          name = "RNAnue";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ pkgs.RNAnue pkgs.ViennaRNA pkgs.segemehl ];
            pathsToLink = [ "/bin" "/share" ];
          };
          config.Cmd = [ "/bin/RNAnue" ];
        };
        singularityRNAnue = pkgs.singularity-tools.buildImage {
          name = "RNAnue";
          contents = [ pkgs.RNAnue pkgs.ViennaRNA pkgs.segemehl ];
          diskSize = 2048;
        };
      }; # packages
    }; # eachSystem 

  in
    # Create the overlay of available software.
    flake-utils.lib.eachDefaultSystem eachSystem // { overlay = final: prev: {
      ViennaRNA = final.callPackage ./viennarna {};
      kraken2 = final.callPackage ./kraken2 {};
      prepkraken2db = final.callPackage ./kraken2/prepdb.nix {};
      RNAnue = (final.callPackage ./RNAnue {}) inputs.RNAnue;
      SeqAn3 = (final.callPackage ./SeqAn3 {}) inputs.SeqAn3;
      sdsl-lite = (final.callPackage ./sdsl-lite {}) inputs.sdsl-lite;
      segemehl = final.callPackage ./segemehl {};
      mummer = final.callPackage ./mummer {};
    };};
}

