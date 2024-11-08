{ pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  libiconv,
  rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "wasmvm";
  version = "2.1.3";

  src = fetchFromGitHub {
    owner = "CosmWasm";
    repo = pname;
    rev = "v${version}";
    sha256 = "15fipysgzpnn0drxl6p86zlwilp81rzmy2wqmjd7fpp187ccm2l1";
  };

  cargoLock = {
    lockFile = "${src}/libwasmvm/Cargo.lock";
    outputHashes = {
      "cosmwasm-core-2.1.4" = "sha256-stKVEC5jJpZhVCPnoeGApKIgpfV8wd+L5hmrhJy9hsU=";
    };
  };

  nativeBuildInputs = [
    libiconv
  ];

  buildPhase = ''
    cd libwasmvm
    cargo build --release
    cd ..
  '';

  postPatch = ''
    ln -s ${src}/libwasmvm/Cargo.lock Cargo.lock
  '';

  installPhase = ''
    mkdir -p $out/lib
    cp libwasmvm/target/release/libwasmvm.* $out/lib
    cp libwasmvm/bindings.h $out/lib

    ls -la $out/lib
  '';

  dontFixup = true;
  doCheck = false;

  meta = with lib; {
    description = "WasmVM is a WebAssembly Virtual Machine.";
    homepage = "https://github.com/CosmWasm/wasmvm";
    license = licenses.mit;
    maintainers = [ "CosmWasm" ];
    platforms = platforms.unix;
  };
}