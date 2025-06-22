{pkgs ? import <nixpkgs> {}}:
pkgs.arion.build {
  modules = [./arion-compose.nix];
  pkgs = import ./arion-pkgs.nix;
}
