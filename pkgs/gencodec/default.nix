{ pkgs, lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gencodec";
  version = "latest";

  src = fetchFromGitHub {
    owner = "brunonascdev";
    repo = "gencodec";
    rev = "master";
    sha256 = "sha256-04TfKllFT/TFF5h6d6RiJoF7/F0JR5UC7OEZDysJ0ls=";
  };

  vendorHash = null;
  doCheck = false;

  # Optional metadata
  meta = with lib; {
    description = "Gencodec is a tool to generate Go code for codec interfaces.";
    homepage = "https://github.com/brunonascdev/gencodec";
    license = licenses.mit;
    maintainers = with maintainers; [ "brunonascdev" ];
  };
}