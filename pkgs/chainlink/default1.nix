{ pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  git,
  python3,
  libobjc,
  IOKit,
  toybox,
  coreutils,
  jq,
  gnumake,
  gencodec,
  python3Packages,
  protobuf,
  protoc-gen-go,
  protoc-gen-go-grpc,
  foundry-bin,
  libgcc,
  curl,
  go-ethereum,
  go,
  gotools,
  gopls,
  delve,
  github-cli,
  pkg-config,
  libudev-zero,
  libusb1,
  postgresql_16,
  nodejs_20,
  pnpm
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "chainlink";
  version = "2.18.0-rc2";

  src = fetchFromGitHub {
    owner = "smartcontractkit";
    repo = "chainlink";
    rev = "v2.18.0-rc2";
    sha256 = "sha256-av5SjX7tVGOoioxrxrwBD+zyyggWQSiYBXD7IvhjYOc=";
    leaveDotGit = true;
  };

  # Optional patches can be applied here if necessary
  patches = [];

  nativeBuildInputs = [
    git
    python3
    python3Packages.pip
    protobuf
    protoc-gen-go
    protoc-gen-go-grpc
    foundry-bin
    curl
    go-ethereum
    libgcc
    postgresql_16
    nodejs_20
    go
    pnpm
    coreutils
    gotools
    gopls
    delve
    github-cli
    toybox
    jq
    gnumake
    gencodec
  ] ++ lib.optionals stdenv.isLinux [
    pkg-config
    libudev-zero
    libusb1
  ];

  # Platform-specific dependencies for Darwin (macOS)
  propagatedBuildInputs = lib.optionals stdenv.isDarwin [
    libobjc
    IOKit
  ];

  # Set up environment and build flags
  preBuild = ''
    # Override $HOME to be writable
    export HOME=$(pwd)

    echo "Setting NPM strict-ssl to false for this build..."
    npm config set strict-ssl false
    npm config rm proxy 
    npm config rm https-proxy
  '';

  # Installation phase to install the Chainlink binary
  installPhase = ''
    GOFLAGS="-ldflags '-X github.com/smartcontractkit/chainlink/v2/core/static.Version=2.17.0 -X github.com/smartcontractkit/chainlink/v2/core/static.Sha=5ebb63266ca697f0649633641bbccb436c2c18bb'" make install
    
    mkdir -p "$out"
    cp -r build/bin "$out/bin"
  '';

  # Environment setup for development shells
  shellHook = ''
    # Add fix for macOS
    ${if stdenv.isDarwin then "source ./nix-darwin-shell-hook.sh" else ""}

    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$PATH
    echo "GOPATH set to $GOPATH"
  '';

  # Metadata for the package
  meta = with lib; {
    description = "Chainlink is a decentralized oracle network.";
    homepage = "https://github.com/smartcontractkit/chainlink";
    license = licenses.mit;
    maintainers = [ "brunonascdev" ];
    platforms = platforms.unix;
  };
})