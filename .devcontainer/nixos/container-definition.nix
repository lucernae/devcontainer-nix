{ system ? builtins.currentSystem, pkgs ? import <nixpkgs> { inherit system; } }:
{
  container = (import (pkgs.path + "/nixos/lib/eval-config.nix") {
    inherit system;
    modules = [
      # disable unnecessary services
      {
        nixpkgs.system = system;
        systemd.services.systemd-logind.enable = false;
        systemd.services.console-getty.enable = false;
      }
      # the configuration modules are shared with other setup to reuse most config
      (import ./configuration.nix)
      # we add a minimal nixos profile
      (pkgs.path + "/nixos/modules/profiles/minimal.nix")
    ];
  }).config.system.build.toplevel;
}
