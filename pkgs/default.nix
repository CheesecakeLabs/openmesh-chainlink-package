{
  self,
  inputs,
  lib,
  ...
}: {
  # add all our packages based on host platform
  flake.overlays.default = _final: prev: let
    inherit (prev.stdenv.hostPlatform) system;
  in
    if builtins.hasAttr system self.packages
    then self.packages.${system}
    else {};

  perSystem = {
    self',
    pkgs,
    system,
    ...
  }: let
    inherit (pkgs) callPackage;
    inherit (lib.extras.flakes) platformPkgs platformApps;
  in {
    packages = platformPkgs system rec {
      chainlink = callPackage ./chainlink { inherit (pkgs.darwin) IOKit libobjc; };
    };

    apps = platformApps self'.packages {
      chainlink = {
        bin = "chainlink";
      };
    };
  };
}