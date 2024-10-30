{ lib, stdenv, buildGoModule, buildGoPackage, fetchFromGitHub, git, python3, postgresql_16, nodejs, pnpm, libobjc, IOKit, toybox, coreutils, jq }:

buildGoModule rec {
  pname = "chainlink";
  version = "2.17.0";  # Example version, update as needed

  # Fetch the Chainlink source code from GitHub
  src = fetchFromGitHub {
    owner = "smartcontractkit";
    repo = "chainlink";
    rev = "v${version}";
    sha256 = "0dyhs7g95abbn3r43camlwwwxnnm9xd3k8v13hkrr25cqw9ggfsi";  # Replace with correct hash using nix-prefetch-url
  };

  # Vendor dependencies to avoid network access during the build
  proxyVendor = true;
  vendorHash = "sha256-fb3DlXdrQw0NBKiOkblcModtLg4zDkBx+AKz/4vcFEY=";  # Replace with correct hash

  # Disable tests for now; can be enabled if needed
  doCheck = false;

  outputs = [ "out" ];

  # Include necessary dependencies
  nativeBuildInputs = [
    git  # To clone the repository and fetch dependencies
    python3  # Python required by solc-select
    postgresql_16  # PostgreSQL for database interactions
    nodejs  # Node.js v20 for required JS tooling
    pnpm  # pnpm v9 for package management
    coreutils  # Coreutils for basic utilities
    toybox  # Toybox for additional tools
    jq  # jq for JSON processing
    # (buildGoPackage rec {
    #   pname = "gencodec";
    #   version = "0.1.0";  # Example version, update if needed
    #   goPackagePath = "github.com/smartcontractkit/gencodec";
    #   src = fetchFromGitHub {
    #     owner = "smartcontractkit";
    #     repo = "gencodec";
    #     rev = "master";  # Use the latest commit or specific tag if needed
    #     sha256 = "0sj7kc0hx08bzccm1hzqz9iks755h6vfm9bwzr448x1jpvd8ad2r";  # Replace with the correct hash
    #   };
    #   vendorHash = null;
    #   doCheck = false;
    #   # goDeps = ./gencodec-packages.nix;
    #   # outputs = [ "out" ];
    #   # buildPhase = ''
    #   #   go build -o gencodec ./cmd/gencodec
    #   # '';
    #   # installPhase = ''
    #   #   mkdir -p $out/bin
    #   #   cp gencodec $out/bin/gencodec

    #   #   export PATH=$PATH:$out/bin  # Add gencodec to PATH
    #   #   echo "Added gencodec to PATH"
    #   # '';
    # })
  ];

  # Build phase following the provided guide
  buildPhase = ''
    # this line removes a bug where value of $HOME is set to a non-writable /homeless-shelter dir
    export HOME=$(pwd)

    echo "Setting NPM strict-ssl to false for this build..."
    npm config set strict-ssl false

    echo "Installing gencodec..."
    export GOPATH=$TMPDIR/go  # Temporary GOPATH
    export PATH=$GOPATH/bin:$PATH

    # Install gencodec using Go
    GO111MODULE=off go install github.com/smartcontractkit/gencodec@latest

    echo "Building Chainlink..."
    make install
  '';

  # Installation phase
  installPhase = ''
    echo "Installing Chainlink binaries..."
    mkdir -p $out/bin
    cp ./bin/chainlink $out/bin/chainlink
  '';

  # Platform-specific fixes for macOS
  propagatedBuildInputs = lib.optionals stdenv.isDarwin [ libobjc IOKit ];

  # Environment setup to ensure Go paths are correctly set
  shellHook = ''
    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$PATH
    echo "GOPATH set to $GOPATH"
  '';

  # Package metadata
  meta = with lib; {
    description = "Chainlink is a decentralized oracle network.";
    homepage = "https://github.com/smartcontractkit/chainlink";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ "brunonascdev" ];
  };
}