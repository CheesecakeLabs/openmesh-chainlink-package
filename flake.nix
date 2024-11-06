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

      # Import Nixpkgs for all systems, add allowUnfree and allowBroken
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
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
          wasmvm = import ./pkgs/wasmvm/default.nix {
            pkgs = pkgs;
            lib = pkgs.lib;
            stdenv = pkgs.stdenv;
            fetchFromGitHub = pkgs.fetchFromGitHub;
            git = pkgs.git;
            go = pkgs.go;
            rustup = pkgs.rustup;
            libiconv = pkgs.libiconv;
          };
          chainlink = import ./pkgs/chainlink/default.nix {
            go = pkgs.go;
            postgresql_16 = pkgs.postgresql_16;
            git = pkgs.git;
            python3 = pkgs.python3;
            python3Packages = pkgs.python3Packages;
            protobuf = pkgs.protobuf;
            protoc-gen-go = pkgs.protoc-gen-go;
            protoc-gen-go-grpc = pkgs.protoc-gen-go-grpc;
            curl = pkgs.curl;
            nodejs_20 = pkgs.nodejs_20;
            pnpm = pkgs.pnpm;
            go-ethereum = pkgs.go-ethereum;
            go-mockery = pkgs.go-mockery;
            gotools = pkgs.gotools;
            gopls = pkgs.gopls;
            delve = pkgs.delve;
            golangci-lint = pkgs.golangci-lint;
            github-cli = pkgs.github-cli;
            jq = pkgs.jq;
            libgcc = pkgs.libgcc;
            coreutils = pkgs.coreutils;
            toybox = pkgs.toybox;
            gnumake = pkgs.gnumake;
            gencodec = self.packages.${system}.gencodec;
            patchelf = pkgs.patchelf;
            libobjc = pkgs.darwin.libobjc;
            wasmvm = self.packages.${system}.wasmvm;
            pkg-config = pkgs.pkg-config;
            libudev-zero = pkgs.libudev-zero;
            libusb1 = pkgs.libusb1;
            IOKit = pkgs.darwin.IOKit;
            pkgs = pkgs;
            lib = pkgs.lib;
            stdenv = pkgs.stdenv;
            fetchFromGitHub = pkgs.fetchFromGitHub;
          };
          # chainlink_slim = import ./pkgs/chainlink/default1.nix {
          #   lib = pkgs.lib;
          #   fetchFromGitHub = pkgs.fetchFromGitHub;
          #   buildGoModule = pkgs.buildGoModule;
          #   gencodec = self.packages.${system}.gencodec;
          # };
        }
      );

      # Make Chainlink the default package
      defaultPackage = forAllSystems (system: self.packages.${system}.chainlink);

      # Define devShell for development
      devShell = forAllSystems (system: 
        nixpkgsFor.${system}.mkShell {
          nativeBuildInputs = [
            self.packages.${system}.gencodec
            # self.packages.${system}.chainlink_slim
            self.packages.${system}.wasmvm
            self.packages.${system}.chainlink
            nixpkgsFor.${system}.go
            nixpkgsFor.${system}.postgresql_16
            nixpkgsFor.${system}.git
            nixpkgsFor.${system}.python3
            nixpkgsFor.${system}.python3Packages.pip
            nixpkgsFor.${system}.protobuf
            nixpkgsFor.${system}.protoc-gen-go
            nixpkgsFor.${system}.protoc-gen-go-grpc
            nixpkgsFor.${system}.curl
            nixpkgsFor.${system}.nodejs_20
            nixpkgsFor.${system}.pnpm
            nixpkgsFor.${system}.go-ethereum
            nixpkgsFor.${system}.go-mockery
            nixpkgsFor.${system}.gotools
            nixpkgsFor.${system}.gopls
            nixpkgsFor.${system}.delve
            nixpkgsFor.${system}.golangci-lint
            nixpkgsFor.${system}.github-cli
            nixpkgsFor.${system}.jq
            nixpkgsFor.${system}.libgcc
            nixpkgsFor.${system}.coreutils
            nixpkgsFor.${system}.toybox
            nixpkgsFor.${system}.gnumake
            nixpkgsFor.${system}.patchelf
            nixpkgsFor.${system}.libiconv
            nixpkgsFor.${system}.rustup
          ] ++ (nixpkgsFor.${system}.lib.optionals nixpkgsFor.${system}.stdenv.isDarwin [
            nixpkgsFor.${system}.darwin.libobjc
            nixpkgsFor.${system}.darwin.IOKit
          ]) ++ (nixpkgsFor.${system}.lib.optionals nixpkgsFor.${system}.stdenv.isLinux [
            nixpkgsFor.${system}.pkg-config
            nixpkgsFor.${system}.libudev-zero
            nixpkgsFor.${system}.libusb1
          ]);
        }
      );

      # NixOS module output for Chainlink
      nixosModules.default = import ./modules/chainlink/default.nix;
    };
}