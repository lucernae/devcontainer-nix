import <nixpkgs> {
  # it is possible to inject the package overrides
  # we use it to inject nix built image tag
  config = {
    packageOverrides = pkgs: {
      dockerTools.streamLayeredImage = args: let
        newArgs = args // {}; # { tag = "nixos-arion"; created = "now"; }; # useful to extends the attrset of arguments
      in
        pkgs.dockerTools.streamLayeredImage newArgs;
    };
  };
  system = "x86_64-linux";
}
