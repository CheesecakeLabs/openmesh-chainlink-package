{
  go,
  postgresql_16,
  git,
  python3,
  python3Packages,
  protobuf,
  protoc-gen-go,
  protoc-gen-go-grpc,
  curl,
  nodejs_20,
  pnpm,
  go-ethereum,
  go-mockery,
  gotools,
  gopls,
  delve,
  golangci-lint,
  github-cli,
  jq,
  libgcc,
  coreutils,
  toybox,
  gnumake,
  gencodec,
  patchelf,
  libobjc,
  wasmvm,
  pkg-config,
  libudev-zero,
  libusb1,
  IOKit,
  pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "chainlink";
  version = "2.18.0";

  src = fetchFromGitHub {
    owner = "smartcontractkit";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-ifu+5fzujIKsZQiOA+3bsh5L34dYfVFG6Nk3p+N5kO4=";
    fetchSubmodules = true;
  };

  nativeBuildInputs =
    [
      go
      postgresql_16
      git
      python3
      python3Packages.pip
      protobuf
      protoc-gen-go
      protoc-gen-go-grpc
      curl
      nodejs_20
      pnpm
      go-ethereum
      go-mockery
      gotools
      gopls
      delve
      golangci-lint
      github-cli
      jq
      libgcc
      coreutils
      toybox
      gnumake
      gencodec
      patchelf
      wasmvm
    ]
    ++ lib.optionals stdenv.isLinux [
      pkg-config
      libudev-zero
      libusb1
    ];

  # Platform-specific dependencies for Darwin (macOS)
  propagatedBuildInputs = lib.optionals stdenv.isDarwin [
    libobjc
    IOKit
  ];

  outputs = [ "out" ];

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

    # Copy the binary to the output directory
    mkdir -p "$out/bin"
    cp chainlink "$out/bin/chainlink"

    # Fix the install_name of the wasmvm dylib
    install_name_tool -id "@rpath/libwasmvm.dylib" ${wasmvm}/lib/libwasmvm.dylib
  '';

  dontFixup = true;

  # Metadata for the package
  meta = with lib; {
    description = "Chainlink is a decentralized oracle network.";
    homepage = "https://github.com/smartcontractkit/chainlink";
    license = licenses.mit;
    maintainers = [ "brunonascdev" ];
    platforms = platforms.unix;
  };
})