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

  # Create passwd and group files for VS Code Dev Containers compatibility
  # These are needed for VS Code to connect (runs `uname -m` probe as root)
  # The NixOS activation will regenerate these at runtime, but these serve as placeholders
  fhsEtc = pkgs.runCommand "fhs-etc" { } ''
    mkdir -p $out/etc
    # passwd: root user (UID 0, GID 0)
    echo "root:x:0:0:root:/root:/run/current-system/sw/bin/zsh" > $out/etc/passwd
    # group: root group (GID 0)
    echo "root:x:0:" > $out/etc/group
    # vscode group (GID 1000) - matches configuration.nix
    echo "vscode:x:1000:" >> $out/etc/group
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
      fhsEtc
    ];
    config = {
      Cmd = [ "${container}/init" ];
    };
  };
}
