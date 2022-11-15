{ pkgs, config, ... }: {
  project.name = "systemd";
  services.devcontainer = { config, pkgs, lib, ... }: {
    nixos.useSystemd = true;
    nixos.configuration = import ./../nixos/configuration.nix;
    service.volumes = [
      "${toString ./../../.}:/workspace:cached"
      "${toString ./../../.devcontainer/nixos/configuration.nix}:/etc/nixos/configuration.nix"
      "${toString ./../../.devcontainer/nixos/devcontainer-patch.nix}:/etc/nixos/devcontainer-patch.nix"
      # used for nested volume mount in docker shared socket
      # "${toString ./../../.}:${toString ./../../.}"
      # used for docker shared socket
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
    image.nixBuild = true;
    image.name = "ghcr.io/lucernae/devcontainer-nix";
    image.enableRecommendedContents = true;
    image.contents = [
      (pkgs.runCommand "lib-link" {} ''
        mkdir -p $out $out/bin
        ln -sf ${config.nixos.build.toplevel}/sw/lib $out/lib || true
        ln -sf ${config.nixos.build.toplevel}/sw/lib $out/lib64 || true
        for f in ${config.nixos.build.toplevel}/sw/bin/*; do
          ln -sf $(${config.nixos.build.toplevel}/sw/bin/readlink $f) $out/bin
        done
      '')
    ];
    # the image tag is defined by arion-pkgs.nix overrides,
    # since we have no way of injecting the tag at the moment.
    # image.tag = "nixos-arion";
    service.hostname = "devcontainer";
    service.capabilities.SYS_ADMIN = true;
    service.capabilities.CAP_NET_ADMIN = true;
    service.privileged = true;
    # you can enable useHostStore if your host is nixos
    # service.useHostStore = true;
    # service.useHostNixDaemon = true;
    service.environment.LD_LIBRARY_PATH = "/lib:/run/current-system/sw/lib";
    service.ports = [
      # you can port forward
      # "8080:80" # host:container
    ];
  };
}
