{ lib, buildGoModule, fetchFromGitHub, git, openssl_3_3 }:

buildGoModule rec {
  pname = "gencodec";
  version = "latest";  # Or specify a specific tag or commit

  # Fetch the source code from GitHub
  src = fetchFromGitHub {
    owner = "brunonascdev";
    repo = "gencodec";
    rev = "master";  # Use a specific commit/tag if needed
    sha256 = "sha256-04TfKllFT/TFF5h6d6RiJoF7/F0JR5UC7OEZDysJ0ls=";  # Replace with the correct hash from prefetch
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
  '';

  # Optional metadata
  meta = with lib; {
    description = "Gencodec is a tool to generate Go code for codec interfaces.";
    homepage = "https://github.com/brunonascdev/gencodec";
    license = licenses.mit;
    maintainers = with maintainers; [ "brunonascdev" ];
  };
}