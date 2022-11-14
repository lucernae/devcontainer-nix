{ system ? builtins.currentSystem, pkgs ? import <nixpkgs> { inherit system; }
}:
with pkgs;
with pkgs.lib;
let
  container = (import <nixpkgs/nixos/lib/eval-config.nix> {
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

  # this is the output if you want to create a docker image and load it using:
  # ./result | docker load -
  layeredImage = dockerTools.streamLayeredImage {
    name = "ghcr.io/lucernae/devcontainer-nix";
    tag = "nixos-dockertools";
    # you can include more packages into the paths and nix store inside the image
    contents = [
      #   pkgs.vim
    ];
    config = { Cmd = [ "${container}/init" ]; };
  };
  tarball = pkgs.callPackage <nixpkgs/nixos/lib/make-system-tarball.nix> {
    storeContents = [{
      symlink = "rootfs";
      object = "${container}";
    }];
    contents = [{
      source = ./configuration.nix;
      target = "etc/nixos/configuration.nix";
    }];
    compressCommand = "cat";
    compressionExtension = "";
  };
  # container
in [
  # the tarball is a build result with rootfs inside
  tarball
  # layeredImage is an executable that can stream the layers
  # ./result-2 | docker load
  layeredImage
]
