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
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-ifu+5fzujIKsZQiOA+3bsh5L34dYfVFG6Nk3p+N5kO4=";
  };

  vendorHash = "sha256-s98pfExSofXZMq2l+ctGgab4gUQ87hUZUZX43PCWLP8=";
  proxyVendor = true;
  # dontFixup = true;

  ldflags = [
    "-X github.com/smartcontractkit/chainlink/v2/core/static.Version=2.18.0"
    "-X github.com/smartcontractkit/chainlink/v2/core/static.Sha=fb7d6e88ea3471909a4f9aa29992ec080bba9057"
  ];

  buildPhase = ''
    go build -ldflags "${lib.concatStringsSep " " ldflags}" .

    ls -la

    # Copy the binary to the output directory
    mkdir -p "$out/bin"
    cp chainlink "$out/bin/chainlink"
  '';

  installPhase = ''
    go install -ldflags "${lib.concatStringsSep " " ldflags}" .   
  '';

  postInstall = ''
    cd contracts && pnpm i
  '';

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

  meta = with lib; {
    description = "Chainlink is a decentralized oracle network.";
    homepage = "https://github.com/smartcontractkit/chainlink";
    license = licenses.mit;
    maintainers = [ "brunonascdev" ];
    platforms = platforms.unix;
  };
}