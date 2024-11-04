{ pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  git,
  libobjc,
  IOKit,
  go,
  rustup,
  libiconv
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "wasmvm";
  version = "2.1.3";

  src = fetchFromGitHub {
    owner = "CosmWasm";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-oY2rfPs6EGrizj0/Hrc4cnxltOrbaIfANoM/SZttaEU=";
    leaveDotGit = true;
  };

  nativeBuildInputs = [
    git
    go
    rustup
    libiconv
  ];

  # Platform-specific dependencies for Darwin (macOS)
  propagatedBuildInputs = lib.optionals stdenv.isDarwin [
    libobjc
    IOKit
  ];

  preBuild = ''
    # Override $HOME to be writable
    export HOME=$(pwd)
  '';

  installPhase = ''
    cd libwasmvm
    rustup default stable
    cargo build --release
    cd ..
    mkdir -p $out/internal/api
    cp libwasmvm/target/release/libwasmvm.dylib $out/internal/api
    cp libwasmvm/bindings.h $out/internal/api
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