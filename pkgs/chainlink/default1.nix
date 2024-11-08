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
  buildGoModule,
}:

buildGoModule rec {
  pname = "chainlink";
  version = "2.18.0";

  src = fetchFromGitHub {
    owner = "smartcontractkit";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-ifu+5fzujIKsZQiOA+3bsh5L34dYfVFG6Nk3p+N5kO4=";
    fetchSubmodules = true;
  };

  vendorHash = lib.fakeHash;
  proxyVendor = true;

  ldflags = [
    "-X github.com/smartcontractkit/chainlink/v2/core/static.Version=2.18.0"
    "-X github.com/smartcontractkit/chainlink/v2/core/static.Sha=0e855379b9f4ff54944f8ee9918b7bbfc0a67469"
  ];

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

  # Installation phase to install the Chainlink binary
  installPhase = ''
    go install -v -ldflags "${joinStrings " " ldflags}" .

    # Copy the binary to the output directory
    mkdir -p "$out/bin"
    cp chainlink "$out/bin/chainlink"

    # get the correct libwasmvm name for the platform
    if [ "$(uname)" == "Darwin" ]; then
      libwasmvm="libwasmvm.dylib"
    else
      libwasmvm="libwasmvm.so"
    fi

    # Fix the install_name of the wasmvm dylib
    # install_name_tool -id "@rpath/$libwasmvm" "$out/lib/$libwasmvm"
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
}