# (Experimental) Devcontainer-Nix with NixOS systems

This devcontainer is integrated with systemd so it can spawn NixOS init phase.
You can run this devcontainer inside a Linux host, because it needs systemd and Linux kernel.
It is also possible to somewhat edit configuration.nix and nixos-rebuild switch it, from inside the containers.
Although the full capabilities is experimental because it runs as containers and a full NixOS systems.

You can use this devcontainer to:
- try NixOS. Although it is recommended to use NixOS vm or qemu instead
- create and test NixOS services using `configuration.nix`

# Development

The image was built using [arion](https://github.com/hercules-ci/arion). See their docs page to know about the details.

If you want to customize the base devcontainer image, it is best to develop inside a real NixOS host.

The directory is provided with minimal [shell.nix](shell.nix) so that the mandatory packages are available.

A shortcut [Makefile](Makefile) is also included for common tasks:

- **config** generate docker-compose config using Arion as `docker-compose.yml`. This file is ignored by git
- **a-build** use Arion to build the image. The image tag will have nix hash
- **a-up** run the compose in attached mode using Arion
- **dc-up** run the compose in attached mode using docker-compose with overrides [docker-compose.override.yml](docker-compose.override.yml). This is useful for Linux host with cgroups that cannot works with read-only mount mode.
- **post-create-command** shortcuts to run setup after systemd is running. such as enabling nix-daemon, dbus, and updating nix-channel.

The mechanism of the development phase is like this:

- provide `configuration.nix` (NixOS configuration files)
- build using arion
- override using `docker-compose.override.yml`
- run and check if systemd is working

Since you have access to most services and systemd capabilities in NixOS, you can reuse some of your services recipes to build a minimal docker-image. Probably less than 1GB with low effort, including cache optimizations.