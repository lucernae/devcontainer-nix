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
      (pkgs.runCommand "lib-link" {
        configSystem = "${config.nixos.build.toplevel}";
      } ''
        # needed for vscode
        mkdir -p $out $out/bin $out/usr/bin $out/etc
        ln -sf $configSystem/sw/lib $out/lib || true
        ln -sf $configSystem/sw/lib $out/lib64 || true
        for f in $configSystem/sw/bin/*; do
          ln -sf "$(readlink $f)" "$out/bin/$(basename $f)"
        done
        # needed for GH codespace
        ln -sf "$(readlink $configSystem/sw/bin/node)" $out/usr/bin/node
      '')

        # needed by vscode and GH codespace to search for users using /etc/passwd
        # we only define minimal values (will be overwritten by init)
      (pkgs.writeTextFile {
          name = "temporary-etc-passwd";
          text = ''
            root:x:0:0:System administrator:/root:/run/current-system/sw/bin/bash
            vscode:x:1000:1000::/home/vscode:/run/current-system/sw/bin/bash
            nobody:x:65534:65534:Unprivileged account (don't use!):/var/empty:/run/current-system/sw/bin/nologin
          '';
          destination = "/etc/passwd";
        } 
      )
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
    service.ports = [
      # you can port forward
      # "8080:80" # host:container
    ];
  };
}
