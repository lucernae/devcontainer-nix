
# Devcontainer with Nix (nix)

Devcontainer with configurable Nix support. Declare your favorite development environment using Nix, and reproduce the environment inside the devcontainers

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| useDirenv | Install direnv and automatically activates the repo when direnv configuration exists | bool | true |
| useFlake | Add Nix Flake Experimental configuration to use Nix Flake | bool | true |
| installRootPackages | Install additional nix packages at build time as root. Package list syntax follows nix flake or nix-env commands, depending on which mode you activated. | string | - |
| prebuildDefaultPackage | If specified, run nix-build on the default.nix package inside the repository. It can be a comma separated lists of package location to be built | string | - |
| prebuildNixShell | If specified, run nix-build on shell.nix package inside the repository. It can be a comma separated lists of package location to be built | string | - |
| prebuildFlake | If specified, run `nix build` on the specified flake URI (can be a remote URI). It can be a comma separated lists of flake URI to be built | string | - |
| prebuildFlakeRun | Like prebuildFlake, but uses `nix run` | string | - |
| prebuildFlakeDevelop | Like prebuildFlake, but uses `nix develop` | string | - |
| additionalNixChannel | Comma separated list of {channel-name}={channel-url} to add. You can also override current nixpkgs channel by setting the channel name to nixpkgs | string | - |
| additionalNixFlakeRegistry | Comma separated list of {flake-name}={flake-registry-uri} to add. You can also override current nixpkgs registry by setting the registry name to nixpkgs | string | - |
| prebuildHomeManager | If specified, install home-manager and activates configuration in a given location. | string | - |
| prebuildHomeManagerFlake | like prebuildHomeManager, but uses Nix Flake URI to specify configuration | string | - |
| imageVariant | devcontainer image variant | string | v1 |



---

_Note: This file was auto-generated from the [devcontainer-template.json](https://github.com/lucernae/devcontainer-nix/blob/main/templates/src/nix/devcontainer-template.json).  Add additional notes to a `NOTES.md`._
