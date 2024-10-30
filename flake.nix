{
  description = "Chainlink Node";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-compat.url = "github:nix-community/flake-compat";
  };

  outputs = { self, nixpkgs, ... }:
    let
      # Supported architectures: x86_64 and aarch64
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Import Nixpkgs for all systems
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      # Define the Chainlink package for all systems
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in {
          gencodec = import ./pkgs/gencodec/default.nix {
            lib = pkgs.lib;
            stdenv = pkgs.stdenv;
            buildGoModule = pkgs.buildGoModule;
            fetchFromGitHub = pkgs.fetchFromGitHub;
            git = pkgs.git;
            jq = pkgs.jq;
          };
          # chainlink = import ./pkgs/chainlink/default.nix {
          #   lib = pkgs.lib;
          #   stdenv = pkgs.stdenv;
          #   buildGoModule = pkgs.buildGoModule;
          #   buildGoPackage = pkgs.buildGoPackage;
          #   fetchFromGitHub = pkgs.fetchFromGitHub;
          #   git = pkgs.git;
          #   python3 = pkgs.python3;
          #   postgresql_16 = pkgs.postgresql_16;
          #   nodejs = pkgs.nodejs;
          #   pnpm = pkgs.pnpm;
          #   coreutils = pkgs.coreutils;
          #   toybox = pkgs.toybox;
          #   libobjc = pkgs.darwin.libobjc;
          #   IOKit = pkgs.darwin.IOKit;
          #   jq = pkgs.jq;
          #   gnumake = pkgs.gnumake;
          # };
        }
      );

      # Make Chainlink the default package
      defaultPackage = forAllSystems (system: self.packages.${system}.chainlink);

      # Define devShell for development
      devShell = forAllSystems (system: 
        nixpkgsFor.${system}.mkShell {
          nativeBuildInputs = [
            self.packages.${system}.chainlink
            # self.packages.${system}.gencodec
            nixpkgsFor.${system}.go
            nixpkgsFor.${system}.git
            nixpkgsFor.${system}.python3
            nixpkgsFor.${system}.postgresql_16
            nixpkgsFor.${system}.nodejs
            nixpkgsFor.${system}.pnpm
            nixpkgsFor.${system}.coreutils
            nixpkgsFor.${system}.toybox
            nixpkgsFor.${system}.jq
          ];
        }
      );

      # NixOS module output for Chainlink
      nixosModules.default = import ./modules/chainlink/default.nix;
    };
}