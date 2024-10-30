{ lib, buildGoPackage, fetchFromGitHub, git }:

buildGoPackage rec {
  pname = "gencodec";
  version = "latest";  # Or specify a specific tag or commit

  # Fetch the source code from GitHub
  src = fetchFromGitHub {
    owner = "smartcontractkit";
    repo = "gencodec";
    rev = "master";  # Use a specific commit/tag if needed
    sha256 = "0sj7kc0hx08bzccm1hzqz9iks755h6vfm9bwzr448x1jpvd8ad2r";  # Replace with the correct hash from prefetch
  };

  # Disable Go modules, as gencodec lacks a go.mod file
  goModInit = false;

  # Build gencodec binary from the command directory
  buildPhase = ''
    mkdir -p $GOPATH/src/github.com/smartcontractkit
    ln -s $src $GOPATH/src/github.com/smartcontractkit/gencodec

    cd $GOPATH/src/github.com/smartcontractkit/gencodec/cmd/gencodec
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
    homepage = "https://github.com/smartcontractkit/gencodec";
    license = licenses.mit;
    maintainers = with maintainers; [ "brunonascdev" ];
  };
}