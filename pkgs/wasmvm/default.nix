{ pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  git,
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

  preBuild = ''
    # Override $HOME to be writable
    export HOME=$(pwd)
  '';

  installPhase = ''
    cd libwasmvm
    rustup default stable
    cargo build --release
    cd ..
    mkdir -p $out/lib
    cp libwasmvm/target/release/libwasmvm.dylib $out/lib
    cp libwasmvm/bindings.h $out/lib

    chmod -R u+w $out
  '';

  dontFixup = true;

  # Metadata for the package
  meta = with lib; {
    description = "WasmVM is a WebAssembly Virtual Machine.";
    homepage = "https://github.com/CosmWasm/wasmvm";
    license = licenses.mit;
    maintainers = [ "CosmWasm" ];
    platforms = platforms.unix;
  };
})