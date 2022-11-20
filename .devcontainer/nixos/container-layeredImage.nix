{ system ? builtins.currentSystem, pkgs ? import <nixpkgs> { inherit system; } }:
let
  container = (import ./container-definition.nix { inherit system pkgs; }).container;
in
with pkgs;
{
  # this is the output if you want to create a docker image and load it using:
  # ./result | docker load
  layeredImage = dockerTools.streamLayeredImage {
    name = "ghcr.io/lucernae/devcontainer-nix";
    tag = "nixos-dockertools";
    # you can include more packages into the paths and nix store inside the image
    contents = [
      #   pkgs.vim
      {
        source = ./configuration.nix;
        target = "etc/nixos/configuration.nix";
      }
      {
        source = ./devcontainer-patch.nix;
        target = "etc/nixos/devcontainer-patch.nix";
      }
    ];
    config = { Cmd = [ "${container}/init" ]; };
  };
}
