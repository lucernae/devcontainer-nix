{
  inputs.nix2container.url = "github:nlewo/nix2container";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  inputs.nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, flake-utils, nixpkgs, nixpkgsUnstable, nix2container }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages = let
        pkgs = nixpkgs.legacyPackages.${system};
        nix2containerPkgs = nix2container.packages.${system};
      in {
        # Push-to-registry format via nix2container (no Docker daemon needed)
        nix2ContainerImage = (import ./container-nix2container.nix {
          inherit system pkgs;
          inherit (nix2containerPkgs) nix2container;
        }).nix2ContainerImage;

        # Streamed layered image for local docker load: ./result | docker load
        layeredImage = (import ./container-layeredImage.nix {
          inherit system pkgs;
        }).layeredImage;
      };
    });
}
