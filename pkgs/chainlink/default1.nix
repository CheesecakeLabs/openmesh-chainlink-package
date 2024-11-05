{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "chainlink";
  version = "2.18.0";

  src = fetchFromGitHub {
    owner = "smartcontractkit";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-9vn3QlmeR5auffTzHwHAH5ZVtx1R8MxAppLzS30v7wc=";
  };

  meta = with lib; {
    description = "A dev tool for SSH auth + Git commit/tag signing using a key stored in Krypton.";
    homepage = "https://krypt.co";
    license = licenses.unfreeRedistributable;
    platforms = platforms.linux ++ platforms.darwin;
  };
}