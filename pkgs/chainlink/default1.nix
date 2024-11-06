{ buildGoModule, fetchFromGitHub, lib, gencodec }:

buildGoModule rec {
  pname = "chainlink";
  version = "2.18.0";

  src = fetchFromGitHub {
    owner = "smartcontractkit";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-ifu+5fzujIKsZQiOA+3bsh5L34dYfVFG6Nk3p+N5kO4=";
  };

  vendorHash = "sha256-mY/XkMBBQaBvhGA0PVaeqOL/Zb5sJy1sdOJ2lODVh6Q=";

  ldflags = [
    "-X github.com/smartcontractkit/chainlink/v2/core/static.Version=${version}"
    "-X github.com/smartcontractkit/chainlink/v2/core/static.Sha=0e855379b9f4ff54944f8ee9918b7bbfc0a67469"
  ];

  meta = with lib; {
    description = "A dev tool for SSH auth + Git commit/tag signing using a key stored in Krypton.";
    homepage = "https://krypt.co";
    license = licenses.unfreeRedistributable;
    platforms = platforms.linux ++ platforms.darwin;
  };
}