{
  description = "Chainlink Node";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-compat.url = "github:nix-community/flake-compat";
    flake-utils.url = "github:numtide/flake-utils";
    foundry.url = "github:shazow/foundry.nix/monthly";
    foundry.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, foundry, ... }:
    let
      # Supported architectures: x86_64 and aarch64
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Import Nixpkgs for all systems
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ foundry.overlay ];
      });
    in
    {
      # Define the Chainlink package for all systems
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in {
          gencodec = import ./pkgs/gencodec/default.nix {
            pkgs = pkgs;
            lib = pkgs.lib;
            buildGoModule = pkgs.buildGoModule;
            fetchFromGitHub = pkgs.fetchFromGitHub;
          };
          chainlink = import ./pkgs/chainlink/default1.nix {
            pkgs = pkgs;
            lib = pkgs.lib;
            stdenv = pkgs.stdenv;
            buildGoModule = pkgs.buildGoModule;
            buildGoPackage = pkgs.buildGoPackage;
            fetchFromGitHub = pkgs.fetchFromGitHub;
            git = pkgs.git;
            python3 = pkgs.python3;
            coreutils = pkgs.coreutils;
            toybox = pkgs.toybox;
            libobjc = pkgs.darwin.libobjc;
            IOKit = pkgs.darwin.IOKit;
            jq = pkgs.jq;
            gnumake = pkgs.gnumake;
            gencodec = self.packages.${system}.gencodec;
            python3Packages = pkgs.python3Packages;
            protobuf = pkgs.protobuf;
            protoc-gen-go = pkgs.protoc-gen-go;
            protoc-gen-go-grpc = pkgs.protoc-gen-go-grpc;
            foundry-bin = pkgs.foundry-bin;
            curl = pkgs.curl;
            go-ethereum = pkgs.go-ethereum;
            gotools = pkgs.gotools;
            gopls = pkgs.gopls;
            delve = pkgs.delve;
            github-cli = pkgs.github-cli;
            pkg-config = pkgs.pkg-config;
            libudev-zero = pkgs.libudev-zero;
            libusb1 = pkgs.libusb1;
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
            self.packages.${system}.gencodec
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