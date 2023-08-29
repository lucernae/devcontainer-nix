# DEVELOPMENT

Since I have no specific direction on how to maintain the repo, we will declare specific convetion here

## Git Branching

The `main` branch is for **stable** changes.
If anything is merged in `main` branch, it has to be tested at the time 
of the merge, so there is a guarantee that it will work on other machine.
Since integration tests for devcontainer is a huge efforts, we mostly 
try to make the image to be at least buildable.
Here's the guideline to do that:

1. Dependencies for the image content **and** the tools to build it needs
   to be pinned by nix or nix flake. Using nix, you can build it locally using
   URI like `nix build github:lucernae/devcontainer-nix#some-output`.
2. Use Nix whenever possible to generate the image. It will utilizes caches
   with deterministic build
3. When rule #2 is not possible, use Nix from inside the Dockerfile instead of
   using imperative command inside the Dockerfile
4. When rule #3 is not possible, use Nix-based image to have deterministic base image
5. When rule #4 is not possible, all hope is lost and we must consider what we are tying to accomplish
6. Extract build parameters as flake inputs or flake overlays inside the outputs
7. When rule #6 is not possible, extract the parameter as Docker build args, so we can 
   supply it via `docker build`, `docker buildx build`, or `docker-compose build` from environment variable
8. Set environment variable using direnv, both locally and in the GitHub workflows
9. In GitHub workflows or any CI/CD pipeline, use the matrix to generate .local.envrc files
   or other needed config files. Then let direnv load the config into environment variables.
10. Separate/factorize configuration files by parallel factors. For example, by 
   default/local-overrides, then branches/tags. This way, you minimizes conflicts when merging changes between branches

By following above 10 rules, our convenient Git branching models:

1. `main` branch is for **stable**, buildable repo.
2. `develop` branch is for **latest**, bleeding edge changes. Most component is buildable, but
    it's okay if some components are not.
3. `channel-<channel-version>` branch is for making fixes for **stable** branches in that specific nix flake channel version.
4. `v<semver-tags>` branch/tag is for orchestration versioning, such as devcontainer templates. Since the tag conveys template, 
   it should be merge-able to channel branches. Orchestration includes github workflows, build recipes, etc.

For this repo we have several terms/glossaries:

1. `devcontainer` refer to OCI containers runs with tooling to integrate according to [devcontainer spec](https://containers.dev)
2. `nix` the package manager inside our devcontainers as tools to integrate directly with nix ecosystems such as direnv, flake, home-manager, configuration.nix
3. `direnv` tools to hook your shells with initialization scripts (such as environment variables, alias, etc), whenever your shells enters a directory containing `.envrc` file
4. `flake` a nix-based way to declare dependencies in a much more precise and hermetic using nix. Nix can read a flake and build/download caches for tools/packages declared by the flake
5. `home-manager` a nix-community tools to set up your home directory using nix config. It can be used to declare default packages, dotfiles, file hook, and many more.
6. `configuration.nix` an official nix configuration file for NixOS Linux Distro. The file declares the whole setup of the OS.
7. `channels` or more specifically, Nix channels is a repository of Nix recipe/functions. Nix code is functional, it produces outputs from inputs. 
   Thus, if versioned, the function will behave the same way. A Nix flake is capable of pinning Nix channels by git commit SHA.

## Image tagging

For each OCI image we produce, it will have the following anatomy:

1. `registry`, for example `ghcr.io` or `docker.io`
2. `owner` or `namespace`, for example `lucernae`. Can be a username or org name
3. `image name` can be hierarchical and basically the name of the OCI image. Think of it as the package of our tools.
   We specifically name it `devcontainer-nix` for the OCI image and `devcontainer-nix/nix` as the template packages.
4. `image tag` is specified after colon `:` after the image name. Can be anything, but we have the following rules

    a. `stable` or `main` tag signifies a `stable` image from `main` branch

    b. `latest` or `develop` tag signifies bleeding age image from `develop` branch

    c. `<component>--<version>` tag signifies additional components with the component version. 
       For example `flake--latest` means using the latest Nix flake support.
       `flake--nixos-23.05` means using Nix flake from channel `nixos-23.05`
    
    d. `---<cal-ver>` or `---v<sem-ver>` this is the suffix of the tag used to canonically associate the image with 
       the git tag producing the image.

