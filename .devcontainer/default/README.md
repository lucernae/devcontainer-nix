# Devcontainer-Nix with direnv

My default setup (pre nix-flake) is to use nix + direnv to setup environment 
and dependencies. We can use devcontainer-nix to bootstrap this environment.

## Setup

Copy both `devcontainer.json` and `docker-compose.yml` file in this directory 
to your own repo's .devcontainer directory.

In `docker-compose.yml` file:
 - In `devcontainer.volumes` key, mount your workspace into the container. In this example, we uses `../../` because the main repo is two-level above this directory.
 - If you use nix multi user setup (recommended), set `devcontainer.environment` keys for `NIX_MULTI_USER` and `NIX_REMOTE`. Otherwise,for single user mode comment this out.

In `devcontainer.json` file:
 - If you use nix multi user setup (recommended), set `remoteUser` key to `vscode` (the default non-root user we created). Otherwise, for single user mode, you need to use `root` as the user.
 - Hook up your setup in the `postCreateCommand` key. For example, for direnv executions, I used `"bash -c \"direnv allow /workspace; direnv exec /workspace sleep 1\""` so that the workspace is automatically allowed and the environment are built when we open vscode terminals.