{
  system ? builtins.currentSystem,
  pkgs ? import <nixpkgs> { inherit system; },
}:
let
  container = (import ./container-definition.nix { inherit system pkgs; }).container;

  # Create a derivation that places config files in the correct location
  # Use the actual files in etc/nixos/ (not the symlinks)
  nixosConfigFiles = pkgs.runCommand "nixos-config-files" { } ''
    mkdir -p $out/etc/nixos
    cp ${./etc/nixos/configuration.nix} $out/etc/nixos/configuration.nix
    cp ${./etc/nixos/devcontainer-patch.nix} $out/etc/nixos/devcontainer-patch.nix
  '';
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
      nixosConfigFiles
    ];
    config = {
      Cmd = [ "${container}/init" ];
    };
  };
}
