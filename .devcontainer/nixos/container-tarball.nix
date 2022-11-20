{ system ? builtins.currentSystem, pkgs ? import <nixpkgs> { inherit system; } }:
let
  container = (import ./container-definition.nix { inherit system pkgs; }).container;
in
with pkgs;
{
  # the tarball is a build result with rootfs inside
  tarball = callPackage <nixpkgs/nixos/lib/make-system-tarball.nix> {
    storeContents = [{
      symlink = "rootfs";
      object = "${container}";
    }];
    contents = [{
      source = ./configuration.nix;
      target = "etc/nixos/configuration.nix";
    }
      {
        source = ./devcontainer-patch.nix;
        target = "etc/nixos/devcontainer-patch.nix";
      }];
    compressCommand = "cat";
    compressionExtension = "";
  };
}
