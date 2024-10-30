{ pkgs, lib, stdenv, buildGoModule, buildGoPackage, fetchFromGitHub, git, python3, libobjc, IOKit, toybox, coreutils, jq, gnumake, gencodec }:
with pkgs; let
  go = go_1_21;
  postgresql = postgresql_14;
  nodejs = nodejs-18_x;
  nodePackages = pkgs.nodePackages.override {inherit nodejs;};
  pnpm = pnpm_9;

  mkShell' = mkShell.override {
    # The current nix default sdk for macOS fails to compile go projects, so we use a newer one for now.
    stdenv =
      if stdenv.isDarwin
      then overrideSDK stdenv "11.0"
      else stdenv;
  };
in
buildGoModule rec {
  pname = "chainlink";
  version = "2.17.0";  # Example version, update as needed

  # Fetch the Chainlink source code from GitHub
  src = fetchFromGitHub {
    owner = "smartcontractkit";
    repo = "chainlink";
    rev = "v${version}";
    sha256 = "0dyhs7g95abbn3r43camlwwwxnnm9xd3k8v13hkrr25cqw9ggfsi";
  };

  # Vendor dependencies to avoid network access during the build
  proxyVendor = true;
  vendorHash = "sha256-fb3DlXdrQw0NBKiOkblcModtLg4zDkBx+AKz/4vcFEY=";

  doCheck = false;

  outputs = [ "out" ];

  # Include necessary dependencies
  nativeBuildInputs = [
    git  # To clone the repository and fetch dependencies
    python3  # Python required by solc-select
    postgresql_16  # PostgreSQL for database interactions
    nodejs  # Node.js v20 for required JS tooling
    pnpm  # pnpm v9 for package management
    coreutils  # Coreutils for basic utilities
    toybox  # Toybox for additional tools
    jq  # jq for JSON processing
    gnumake  # GNU Make for building
    gencodec  # gencodec for Go code generation
  ];

  # Build phase following the provided guide
  buildPhase = ''
    # this line removes a bug where value of $HOME is set to a non-writable /homeless-shelter dir
    export HOME=$(pwd)

    echo "Setting NPM strict-ssl to false for this build..."
    npm config set strict-ssl false
    npm config rm proxy 
    npm config rm https-proxy
  '';

  # Installation phase
  installPhase = ''
    which gencodec
    make install
    # echo "Installing Chainlink binaries..."
    # mkdir -p $out/bin
    # cp ./bin/chainlink $out/bin/chainlink
  '';

  # Platform-specific fixes for macOS
  propagatedBuildInputs = lib.optionals stdenv.isDarwin [ libobjc IOKit ];

  # Environment setup to ensure Go paths are correctly set
  shellHook = ''
    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$PATH
    echo "GOPATH set to $GOPATH"
    source ./nix-darwin-shell-hook.sh
  '';

  # Package metadata
  meta = with lib; {
    description = "Chainlink is a decentralized oracle network.";
    homepage = "https://github.com/smartcontractkit/chainlink";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ "brunonascdev" ];
  };
}