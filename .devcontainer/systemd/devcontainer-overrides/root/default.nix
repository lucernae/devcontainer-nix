{ pkgs ? import <nixpkgs> { } }:
let
  docker-utils = import ./docker.nix { inherit(pkgs); };
in
with pkgs;
buildEnv {
  name = "devcontainer-root-overrides";
  paths = [
    systemd
    docker-utils
  ];
  meta = {
    description = "VS Code devcontainer packages Nix";
    maintainers = [ "Rizky Maulana Nugraha <lana.pcfre@gmail.com>" ];
    priority = 6;
  };
}
