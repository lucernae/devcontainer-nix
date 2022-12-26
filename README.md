# Devcontainer for Nix

[![Open the repo in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=511455788)

[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/lucernae/devcontainer-nix)

VSCode devcontainer for Nix

This devcontainer contains Nix and hooks to install nix recipe as devcontainers.
This is the base image that can be used to extend your own devcontainer based on nix.

# How to use

This repo contains devcontainer templates to make it easy to generate devcontainer configurations. If you prefer 
a more hands on approach, you can also check out sample configuration described in the [next section](#currently-available-devcontainer-samples)

In your own repo, simply copy our [.devcontainer](.devcontainer) directory and extend as necessary using the provided files that directory:

- `default.nix` replace with your nix recipe. You can also include recipes in other repo by including it in this recipe
- `Dockerfile` if you need to extend the image and include several files here
- `docker-compose.yml` if you need to extend docker-compose recipe to do/mount extra things for your devcontainer
- `devcontainer.json` if you need to include custom settings like extensions, etc.

To generate these files using devcontainer CLI, you first need to install the CLI. It is usually packaged along VS Code's Remote Containers extensions tools. So you probably have it already.

The template definition and available options is located in the [template source directory](./templates/src/nix/README.md)

From your own repository directory, create a .devcontainer directory with the options JSON file

```bash
mkdir -p .devcontainer
touch .devcontainer/args.json
```

The file `args.json` contains the options you want to activate and pass to devcontainer CLI. This is an example to use Direnv and Flake:

```json
{
    "useDirenv": "true",
    "useFlake": "false"
}
```

Generate the devcontainers file using CLI, and the template package `ghcr.io/lucernae/devcontainer-nix/nix:1`:

```bash
devcontainer templates apply -t ghcr.io/lucernae/devcontainer-nix/nix:1 --workspace-folder . -a "$(cat .devcontainer/args.json)"
```

Once the files are generated, you can use VS Code's command "Reopen in Container" (available from the command palette: CTRL+SHIFT+P), or `devcontainer up` command to test the devcontainer creations:

```bash
devcontainer up --workspace-folder .
```

# Currently available devcontainer samples

- [default](.devcontainer/default/): minimal example on how to use the devcontainer with direnv
- [development](.devcontainer/development/): my preferred way of using GitHub Codespace to bootstrap this own repo's development
- [home-manager](.devcontainer/home-manager/): (TBD) use flake URI to fetch your home-manager config to setup the devcontainer
- [nixos](.devcontainer/nixos-arion/): use a [codespace template](https://github.com/lucernae/codespaces-nixos-template) to bootstrap a NixOS as a container.
  You can then use NixOS capabilities, such as systemd services definitions, NixOS modules, etc.

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

# Supporting and Contributing

If you like this project, show your love. Even feedbacks are most appreciated.

## Sponsoring

You can sponsor this project to help me experiment with the codespace, since I mostly run out of codespace 
storage quota pretty quickly. The storage was mostly used when you are experimenting with lots of 
packages that fills out Nix store. The final image itself is less than 1GB. By sponsoring, I can avoid
running low of storage quotas.

## Contributing

There are no clear guideline yet. Since this is a template, you can contribute your own recipes, and I can 
publish it as a branch so people can use it quickly. Do you have some cool examples on how to use Nix, Nix flakes, or Home Manager? Feel free to publish it here. You might be helping someone.

Do you have some problem with Nix? You can even use this template so people can see and try out your 
configuration to debug the problem.

## Not able to sponsor or contribute?

No worries, spreading the words or starring the repo might help as well. Thank you!

# References/Remarks

- Thanks to [Arion](https://github.com/hercules-ci/arion). I built the image in Nix using this tools.
- Thanks to Nix Community who helps and provides docs/articles for introverts like me.