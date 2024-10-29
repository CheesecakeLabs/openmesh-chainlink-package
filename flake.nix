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
          chainlink = import ./pkgs/chainlink/default.nix {
            lib = pkgs.lib;
            stdenv = pkgs.stdenv;
            buildGoModule = pkgs.buildGoModule;
            fetchFromGitHub = pkgs.fetchFromGitHub;
            git = pkgs.git;
            python3 = pkgs.python3;
            postgresql_16 = pkgs.postgresql_16;
            nodejs = pkgs.nodejs;
            pnpm = pkgs.pnpm;
            toybox = pkgs.toybox;
            libobjc = pkgs.darwin.libobjc;
            IOKit = pkgs.darwin.IOKit;
          };
        }
      );

      # Make Chainlink the default package
      defaultPackage = forAllSystems (system: self.packages.${system}.chainlink);

      # Define devShell for development
      devShell = forAllSystems (system: 
        nixpkgsFor.${system}.mkShell {
          nativeBuildInputs = [
            self.packages.${system}.chainlink
            nixpkgsFor.${system}.go
            nixpkgsFor.${system}.git
            nixpkgsFor.${system}.python3
            nixpkgsFor.${system}.postgresql_16
            nixpkgsFor.${system}.nodejs
            nixpkgsFor.${system}.pnpm
            nixpkgsFor.${system}.toybox
          ];
        }
      );

      # NixOS module output for Chainlink
      nixosModules.default = import ./modules/chainlink/default.nix;
    };
}