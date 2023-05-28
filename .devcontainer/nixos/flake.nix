{
  inputs.nix2container.url = "github:nlewo/nix2container";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
  inputs.nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, flake-utils, nixpkgs, nixpkgsUnstable, nix2container }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages =
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nix2containerPkgs = nix2container.packages.${system};
        in
        {
          nix2ContainerImage = (import ./container-nix2container.nix {
            inherit system pkgs;
            inherit (nix2containerPkgs) nix2container;
          }).nix2ContainerImage;
        };
    });
}
