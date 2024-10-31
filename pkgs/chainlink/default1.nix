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
  curl,
  go-ethereum,
  gotools,
  gopls,
  delve,
  github-cli,
  pkg-config,
  libudev-zero,
  libusb1
}:

stdenv.mkDerivation {
  pname = "chainlink";
  version = "2.17.0";

  src = fetchFromGitHub {
    owner = "smartcontractkit";
    repo = "chainlink";
    rev = "v${version}";
    sha256 = "0dyhs7g95abbn3r43camlwwwxnnm9xd3k8v13hkrr25cqw9ggfsi";
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
    pkgs.postgresql_16
    pkgs.nodejs-20_x
    pkgs.pnpm
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

    # Unset GOFLAGS specifically for go mod download
    echo "Downloading Go dependencies without GOFLAGS..."
    env -u GOFLAGS go mod download

    # Re-set GOFLAGS for the build process
    export GOFLAGS="-ldflags '-X github.com/smartcontractkit/chainlink/v2/core/static.Version=v${version} -X github.com/smartcontractkit/chainlink/v2/core/static.Sha=5ebb63266ca697f0649633641bbccb436c2c18bb'"

    echo "Setting NPM strict-ssl to false for this build..."
    npm config set strict-ssl false
    npm config rm proxy 
    npm config rm https-proxy
  '';

  # The main build process
  buildPhase = ''
    make build
  '';

  # Installation phase to install the Chainlink binary
  installPhase = ''
    make install
    cp -r $src $out
  '';

  # Environment setup for development shells
  shellHook = ''
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
}