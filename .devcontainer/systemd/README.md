# Devcontainer-Nix with docker and docker-compose custom setup

This configurations is to expose docker and docker-compose inside the devcontainer.
This setup needs a little more customizations because of how GitHub codespaces works.
For GitHub codespace to recognize docker inside the devcontainer we need:

 - mount `/var/run/docker.sock` (shared docker socket to the container)
 - change docker socket group to vscode (so that non-root user and vscode extension can access it)
 - enable vscode-docker extension to access docker socket

In addition to enabling docker in GitHub codespace, this example also demonstrate how to 
override/built custom devcontainer on top of existing devcontainer-nix.

 - install [devcontainer-overrides](devcontainer-overrides/root/default.nix) package as root, to wrap docker and docker-compose CLI.
 - add entrypoint override to make sure docker socket is owned by vscode group and docker buildx is enabled

## Setup

Copy files in this directory to your own repo's .devcontainer directory.

In `docker-compose.yml` file:
 - In `devcontainer.volumes` key, mount your workspace into the container. In this example, we uses `../../` because the main repo is two-level above this directory.
 - If you use nix multi user setup (recommended), set `devcontainer.environment` keys for `NIX_MULTI_USER` and `NIX_REMOTE`. Otherwise,for single user mode comment this out.
 - In `devcontainer.volumes` key mount the docker socket
 - In `devcontainer.build` key describe your new Dockerfile overrides
 - In `devcontainer.entrypoint` key, use your new entrypoint override script

In `devcontainer.json` file:
 - If you use nix multi user setup (recommended), set `remoteUser` key to `vscode` (the default non-root user we created). Otherwise, for single user mode, you need to use `root` as the user.
 - Hook up your setup in the `postCreateCommand` key. For example, for direnv executions, I used `"bash -c \"direnv allow /workspace; direnv exec /workspace sleep 1\""` so that the workspace is automatically allowed and the environment are built when we open vscode terminals.
 - In `customizations.vscode.extensions`, we also include `ms-azuretools.vscode-docker`