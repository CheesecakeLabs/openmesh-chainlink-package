{ pkgs, lib, stdenv, buildGoModule, buildGoPackage, fetchFromGitHub, git, python3, postgresql_16, nodejs, pnpm, libobjc, IOKit, toybox, coreutils, jq, gnumake }:

let
  goVersion = "1.22";
  nodeVersion = "20.0.0";  # Version constraint for Node.js
in

pkgs.mkShell {
  name = "chainlink";

  buildInputs = with pkgs; [
    # Go programming language (version 1.22)
    (pkgs.go_1_22.overrideAttrs (old: {
      postInstall = ''
        export GOPATH=$HOME/go
        export PATH=$GOPATH/bin:$PATH
      '';
    }))
    
    # Node.js v20 with pnpm v9
    nodejs
    pnpm

    # PostgreSQL 16.x
    postgresql_16

    # Python 3 (required by solc-select)
    python3

    # Git for cloning Chainlink
    git

    # Additional tools
    toybox coreutils jq gnumake
  ];

  shellHook = ''
    echo "Starting Chainlink Node Setup..."

    # Set GOPATH and add Go binaries to PATH
    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$PATH

    # Verify Node.js and pnpm installation
    echo "Using Node.js version: $(node -v)"
    echo "Using pnpm version: $(pnpm -v)"

    # Clone the Chainlink repository if it doesn't exist
    if [ ! -d "chainlink" ]; then
      echo "Cloning Chainlink repository..."
      git clone https://github.com/smartcontractkit/chainlink.git
    fi
    cd chainlink

    # Build the Chainlink node
    echo "Building Chainlink..."
    make install

    echo "Chainlink built successfully. Run the node with: chainlink help"
  '';
}