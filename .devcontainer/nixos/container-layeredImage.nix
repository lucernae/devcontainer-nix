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

  # Create FHS symlinks needed for Docker/VS Code compatibility
  fhsSymlinks = pkgs.runCommand "fhs-symlinks" { } ''
    mkdir -p $out/bin $out/usr/bin $out/usr/sbin
    # Essential shells for VS Code and Docker
    ln -s ${pkgs.bash}/bin/bash $out/bin/bash
    ln -s ${pkgs.bash}/bin/bash $out/bin/sh
    ln -s ${pkgs.bash}/bin/bash $out/usr/bin/bash
    ln -s ${pkgs.bash}/bin/bash $out/usr/bin/sh
    # Core utilities often expected in /bin
    ln -s ${pkgs.coreutils}/bin/env $out/usr/bin/env
    ln -s ${pkgs.coreutils}/bin/env $out/bin/env
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
      fhsSymlinks
    ];
    config = {
      Cmd = [ "${container}/init" ];
    };
  };
}
