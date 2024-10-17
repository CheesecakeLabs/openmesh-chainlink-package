{ pkgs ? import <nixpkgs> {} }:

let
  goVersion = "1.22";
  nodeVersion = "20.0.0";
in
pkgs.mkShell {
  name = "chainlink-node-env";

  buildInputs = with pkgs; [
    # Go programming language
    (pkgs.go_1_22.overrideAttrs (old: {
      postInstall = ''
        export GOPATH=$HOME/go
        export PATH=$GOPATH/bin:$PATH
      '';
    }))

    # Node.js v20 and pnpm v9
    (pkgs.nodejs.overrideAttrs (oldAttrs: rec {
      version = nodeVersion;
    }))
    pnpm

    # PostgreSQL (12.x or later, selecting 16.x)
    postgresql_16

    # Python 3 for solc-select
    python3

    # Git to clone Chainlink
    git
  ];

  shellHook = ''
    echo "Starting Chainlink Node Setup..."

    # Set GOPATH and add Go binaries to PATH
    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$PATH

    # Set up Node.js via nvm
    export NODE_VERSION=${nodeVersion}
    if ! command -v nvm &> /dev/null; then
      echo "Installing nvm..."
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    fi
    nvm install $NODE_VERSION
    nvm use $NODE_VERSION

    # Install pnpm
    npm install -g pnpm@9

    # Clone Chainlink repository
    if [ ! -d "chainlink" ]; then
      git clone https://github.com/smartcontractkit/chainlink.git
    fi
    cd chainlink

    # Build Chainlink node
    echo "Building Chainlink..."
    make install

    echo "Chainlink built successfully. Run the node with: chainlink help"
  '';
}