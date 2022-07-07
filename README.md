# Devcontainer for Nix

VSCode devcontainer for Nix

This devcontainer contains Nix and hooks to install nix recipe as devcontainers.
This is the base image that can be used to extend your own devcontainer based on nix.

# How to use

In your own repo, simply copy our [.devcontainer](.devcontainer) directory and extend as necessary using the provided files that directory:

- `default.nix` replace with your nix recipe. You can also include recipes in other repo by including it in this recipe
- `Dockerfile` if you need to extend the image and include several files here
- `docker-compose.yml` if you need to extend docker-compose recipe to do/mount extra things for your devcontainer
- `devcontainer.json` if you need to include custom settings like extensions, etc.

# Development

This repository mainly contains Docker recipe to build the devcontainer image.

Required tech stack:
- Nix
- Docker/Docker Compose
- Bash

Building the image:

```
make build
```

Running the stack locally:

```
make up
```

