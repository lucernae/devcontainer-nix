{ system ? builtins.currentSystem, pkgs ? import <nixpkgs> { inherit system; }
}:
with pkgs;
with pkgs.lib;

let

  container = (import <nixpkgs/nixos/lib/eval-config.nix> {
    modules = [
      {
        nixpkgs.system = system;
        systemd.services.systemd-logind.enable = false;
        systemd.services.console-getty.enable = false;
      }
      (import ./nixos/configuration.nix)
      (pkgs.path + "/nixos/modules/profiles/minimal.nix")
    ];
  }).config.system.build.toplevel;

in dockerTools.buildImage {
  name = "ghcr.io/lucernae/devcontainer-nix";
  tag = "nixos-dockertools";
  # contents = [ 
  #   pkgs.systemd
  #   container
  # ];
  config = { Cmd = [ "${container}/init" ]; };
}
