{ pkgs, ... }: {
  project.name = "systemd";
  services.devcontainer = { config, pkgs, lib, ... }: {
    nixos.useSystemd = true;
    nixos.configuration = import ./../nixos/configuration.nix;
    service.volumes = [
      "${toString /workspaces/devcontainer-nix}:/workspace:cached"
      "${toString /workspaces/devcontainer-nix/.devcontainer/systemd/nixos/configuration.nix}:/etc/nixos/configuration.nix"
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
    image.nixBuild = true;
    image.name = "ghcr.io/lucernae/devcontainer-nix";
    # the image tag is defined by arion-pkgs.nix overrides,
    # since we have no way of injecting the tag at the moment.
    # image.tag = "nixos-arion";
    service.hostname = "devcontainer";
    service.capabilities.SYS_ADMIN = true;
    service.privileged = true;
    # you can enable useHostStore if your host is nixos
    # service.useHostStore = true;
    # service.useHostNixDaemon = true;
    service.ports = [
      # you can port forward
      # "8080:80" # host:container
    ];
  };
}
