{
  system ? builtins.currentSystem,
  pkgs ? import <nixpkgs> {inherit system;},
  nix2container,
}: let
  container = (import ./container-definition.nix {inherit system pkgs;}).container;
in {
  nix2ContainerImage = nix2container.buildImage {
    name = "ghcr.io/lucernae/devcontainer-nix";
    tag = "nixos-dockertools--nix2container";
    # you can include more packages into the paths and nix store inside the image
    copyToRoot = pkgs.buildEnv {
      name = "default-configuration";
      paths = [
        # pkgs.vim
        ./etc/nixos
      ];
    };
    initializeNixDatabase = true;
    config = {Cmd = ["${container}/init"];};
  };
}
