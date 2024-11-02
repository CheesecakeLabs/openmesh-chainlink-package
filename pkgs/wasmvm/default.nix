{ pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  git,
  libobjc,
  IOKit,
  go,
  rustup
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "wasmvm";
  version = "2.1.3";

  src = fetchFromGitHub {
    owner = "CosmWasm";
    repo = pname;
    rev = "v${version}";
    sha256 = "";
    leaveDotGit = true;
  };

  nativeBuildInputs = [
    git
    go
    rustup
  ];

  # Platform-specific dependencies for Darwin (macOS)
  propagatedBuildInputs = lib.optionals stdenv.isDarwin [
    libobjc
    IOKit
  ];

  # Installation phase to install the Chainlink binary
  installPhase = ''
    make build-libwasmvm
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
    description = "WasmVM is a WebAssembly Virtual Machine.";
    homepage = "https://github.com/CosmWasm/wasmvm";
    license = licenses.mit;
    maintainers = [ "CosmWasm" ];
    platforms = platforms.unix;
  };
})