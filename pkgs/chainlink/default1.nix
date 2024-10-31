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
  pnpm,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "chainlink";
  version = "2.18.0-rc2";

  src = fetchFromGitHub {
    owner = "smartcontractkit";
    repo = "chainlink";
    rev = "v2.18.0-rc2";
    sha256 = "sha256-juyRD6CJ54pbKkyBt7odYkwGx2kmUl5yT3PT7Q6DDBM=";
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
    # run sed to replace GOFLAG lines
    sed -i "" 's/GO_LDFLAGS := $(shell tools\/bin\/ldflags)//g' GNUmakefile && sed -i "" 's/\$(GO_LDFLAGS)/-X github.com\/smartcontractkit\/chainlink\/v2\/core\/static.Version=2.18.0 -X github.com\/smartcontractkit\/chainlink\/v2\/core\/static.Sha=0e855379b9f4ff54944f8ee9918b7bbfc0a67469/g' GNUmakefile

    make install

    make chainlink

    # Copy the binary to the output directory
    mkdir -p "$out/bin"
    cp chainlink "$out/bin/chainlink"
  '';

  dontFixup = true;

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
})