{ lib, buildGoModule, fetchFromGitHub, git, openssl_3_3 }:

buildGoModule rec {
  pname = "gencodec";
  version = "latest";  # Or specify a specific tag or commit

  # Fetch the source code from GitHub
  src = fetchFromGitHub {
    owner = "brunonascdev";
    repo = "gencodec";
    rev = "master";  # Use a specific commit/tag if needed
    sha256 = "sha256-WTSF2r4ydERI/nyl6raBpRw9Y/r4w1AZ+wuBDgGbR2o=";  # Replace with the correct hash from prefetch
  };

  vendorHash = null;

  nativeBuildInputs = [
    git  # To clone the repository and fetch dependencies
    openssl_3_3 # OpenSSL for cryptographic functions
  ];

  # Build gencodec binary from the command directory
  buildPhase = ''
    mkdir -p $GOPATH/src/github.com/brunonascdev
    ln -s $src $GOPATH/src/github.com/brunonascdev/gencodec

    cd $GOPATH/src/github.com/brunonascdev/gencodec
    echo "Building gencodec..."

    go build -o gencodec
  '';

  # Install the binary into $out/bin
  installPhase = ''
    mkdir -p $out/bin
    cp gencodec $out/bin/

    # start go.mod
    mkdir -p $out/src/github.com/brunonascdev/gencodec
    cp -r . $out/src/github.com/brunonascdev/gencodec
    cd $out/src/github.com/brunonascdev/gencodec
    go mod init github.com/brunonascdev/gencodec
    go mod tidy
  '';

  # Optional metadata
  meta = with lib; {
    description = "Gencodec is a tool to generate Go code for codec interfaces.";
    homepage = "https://github.com/brunonascdev/gencodec";
    license = licenses.mit;
    maintainers = with maintainers; [ "brunonascdev" ];
  };
}