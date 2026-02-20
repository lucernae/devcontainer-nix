# CLAUDE.md

This file provides guidance for AI assistants working in this repository.

## Repository Overview

`devcontainer-nix` is a VS Code / GitHub Codespaces devcontainer base image built on [Nix](https://nixos.org/). It provides:

- A Docker image pre-configured with Nix, direnv, home-manager, and related tools
- Devcontainer templates for users to bootstrap Nix-based devcontainers in their own repos
- Sample devcontainer configurations for various use cases (default, development, NixOS, NixOS-arion)

The image is published to `ghcr.io/lucernae/devcontainer-nix`.

## Directory Structure

```
.
├── Dockerfile                   # Main Dockerfile (nix-channel based)
├── Dockerfile-flake             # Alternate Dockerfile using Nix Flakes
├── docker-compose.yml           # Compose file for local build/run
├── docker-compose.flake.yml     # Compose file for flake variant
├── flake.nix                    # Nix Flake definition (inputs + outputs)
├── flake.lock                   # Pinned flake inputs
├── default.nix                  # User-space devcontainer derivation
├── packages.nix                 # Default packages installed in user profile
├── shell.nix                    # Nix shell for local development
├── nix.conf                     # Nix config baked into the image
├── entrypoint.sh                # Container entrypoint (activates direnv)
├── default-packages-priority.sh # Sets nix priority for classic install
├── default-packages-priority-flake.sh  # Sets nix priority for flake install
├── root/
│   ├── default.nix              # Root-level packages (e.g. sudo)
│   └── etc/
│       ├── os-release           # Overrides OS identification for VS Code
│       └── sudoers              # Sudoers config
├── .devcontainer/               # Sample devcontainer configurations
│   ├── devcontainer.json        # Root-level devcontainer config
│   ├── docker-compose.yml       # Root-level compose override
│   ├── nix.conf                 # Nix config for devcontainer use
│   ├── default/                 # Minimal direnv example
│   ├── development/             # Bootstrap config for developing this repo
│   ├── nixos/                   # Experimental NixOS-in-container (Dockerfile + flake)
│   └── nixos-arion/             # NixOS-in-container via Arion (preferred)
├── templates/
│   ├── src/nix/                 # Devcontainer template published to GHCR
│   │   ├── devcontainer-template.json   # Template metadata and options
│   │   ├── README.md            # Auto-generated template docs
│   │   └── .devcontainer/
│   │       ├── Dockerfile
│   │       ├── devcontainer.json
│   │       ├── docker-compose.yml
│   │       └── library-scripts/
│   │           ├── build/       # Scripts run at image build time
│   │           └── runtime/     # Scripts run at container startup
│   ├── build.sh                 # Manual build helper
│   ├── devcontainer-apply-manual.sh
│   ├── devcontainer-publish-manual.sh
│   ├── devcontainer-up-manual.sh
│   └── test.sh
├── .github/
│   └── workflows/
│       ├── build-base.yaml             # Build and push base Nix images via flake
│       ├── build-push-latest.yaml      # Build and push main devcontainer image
│       ├── build-push-latest-flake.yaml
│       ├── build-push-latest-nixos.yaml
│       ├── build-push-latest-nixos-arion.yaml
│       ├── release.yaml                # Publish devcontainer templates + auto-docs
│       └── test-pr.yaml                # Smoke-test templates on PRs
├── .envrc                       # Direnv config for local development
├── renovate.json                # Renovate bot config (auto-updates flake.lock)
├── Makefile                     # Shortcuts: build, up, exec, down
├── README.md                    # User-facing documentation
└── DEVELOPMENT.md               # Contributor conventions and branching model
```

## Key Concepts and Glossary

| Term | Meaning |
|---|---|
| **devcontainer** | OCI container running per the [devcontainer spec](https://containers.dev) for VS Code / Codespaces |
| **nix** | The package manager inside containers; used instead of apt |
| **direnv** | Shell hook that loads `.envrc` when entering a directory |
| **flake** | Nix's hermetic, pinned dependency system (`flake.nix` + `flake.lock`) |
| **home-manager** | Nix community tool for managing user home environment declaratively |
| **configuration.nix** | NixOS system configuration file |
| **channels** | Nix package repositories, pinned by commit SHA in flakes |
| **nixpkgs** | The main Nix package collection; used as channel name in devcontainers |

## Development Workflow

### Prerequisites

- Docker and Docker Compose
- Nix (with flakes enabled)
- direnv

### Local Development Environment

```bash
# Activate the environment via direnv (reads .envrc)
direnv allow

# Or use nix-shell directly
nix-shell
```

The `.envrc` at the repo root sets these key variables (overridable via `.local.envrc` or `.local.env`):

| Variable | Default | Purpose |
|---|---|---|
| `NIXOS_VERSION` | `nixos-25.05` | Nix channel version for the image |
| `MAIN_NIX_CHANNEL` | `https://nixos.org/channels/nixos-25.05` | Channel URL |
| `HOME_MANAGER_VERSION_STRING` | `25.05` | home-manager release |
| `HOME_MANAGER_CHANNEL` | release-25.05 tarball URL | home-manager channel |
| `BOOTSTRAP_NIX_CONFIG` | _(empty)_ | Extra nix.conf content injected at build |

### Common Make Targets

```bash
make build   # docker-compose build
make up      # docker-compose up -d
make exec    # docker-compose exec devcontainer bash
make down    # docker-compose down
```

### Building the Image Locally

```bash
# Classic channel-based build
docker-compose build

# Or with environment overrides
NIXOS_VERSION=nixos-unstable docker-compose build
```

### Using Nix Flakes to Build

```bash
# Build the base image via flake
nix build '.#packages.x86_64-linux.base-devcontainer."nixos-25.05"'

# Build user-space packages
nix build '.#packages.x86_64-linux.devcontainer-packages'

# Enter dev shell
nix develop
```

## Image Architecture

### Two Dockerfile Variants

1. **`Dockerfile`** – Classic channel-based approach
   - Uses `nix-channel` + `nix-env -if` to install packages
   - Simpler but less hermetic

2. **`Dockerfile-flake`** – Flake-based approach
   - Uses `nix profile install` from a local flake
   - More reproducible; preferred for stable releases

Both start from `ghcr.io/lucernae/devcontainer-nix:base--<NIXOS_VERSION>`, which is built via `flake.nix` using `docker-nixpkgs`.

### Build Arguments

| Arg | Default | Description |
|---|---|---|
| `NIXOS_VERSION` | `nixos-25.05` | Selects the base image tag |
| `USERNAME` | `vscode` | Non-root user created in the container |
| `USER_UID` / `USER_GID` | `1000` | UID/GID for the user |
| `MAIN_NIX_CHANNEL` | nixos-25.05 URL | Nix channel added for root and user |
| `HOME_MANAGER_CHANNEL` | release-25.05 URL | home-manager channel |
| `NIX_CONFIG` | _(empty)_ | Extra content appended to `/etc/nix/nix.conf` |

### Package Layers

| File | Installed As | Purpose |
|---|---|---|
| `root/default.nix` | root user, via `nix-env` | Root-level packages (sudo, etc.) |
| `packages.nix` | vscode user, priority 6 | Default user packages (direnv, git, zsh, vim, nodejs, …) |
| `default.nix` | vscode user, priority 6 | Placeholder derivation; extend to add libstdc++ etc. |

### Entrypoint

`entrypoint.sh` runs at container start:
1. Resets `/tmp` ACL (required for Nix build sandbox)
2. Optionally starts `nix-daemon` if `NIX_MULTI_USER` is set
3. `cd`s to the first argument (defaults to `.`)
4. If `.envrc` exists, calls `direnv allow` + `direnv exec` to activate the environment
5. Executes the remaining arguments as the command

## Devcontainer Samples

| Directory | Description |
|---|---|
| `.devcontainer/default/` | Minimal example with direnv |
| `.devcontainer/development/` | Bootstrap for developing this repo in Codespaces |
| `.devcontainer/nixos/` | Experimental: NixOS container built via Dockerfile + nix2container |
| `.devcontainer/nixos-arion/` | Preferred NixOS-in-container using [Arion](https://github.com/hercules-ci/arion); supports systemd |

### NixOS-Arion Development Workflow

```bash
cd .devcontainer/nixos-arion
nix-shell  # activates shell.nix with arion + docker-compose

make config          # generate docker-compose.yml via arion
make a-build         # build image with arion
make a-up            # run compose (attached)
make dc-up           # run via docker-compose with overrides
make post-create-command  # post-setup (nix-daemon, dbus, channel update)
```

## Devcontainer Template

The template published to `ghcr.io/lucernae/devcontainer-nix/nix:<tag>` lives in `templates/src/nix/`.

### Applying the Template

```bash
mkdir -p .devcontainer
# Create args.json with desired options
devcontainer templates apply \
  -t ghcr.io/lucernae/devcontainer-nix/nix:1 \
  --workspace-folder . \
  -a "$(cat .devcontainer/args.json)"
```

### Template Options

| Option | Type | Default | Description |
|---|---|---|---|
| `useDirenv` | bool | `true` | Hook shell with direnv |
| `useFlake` | bool | `true` | Enable Nix flake experimental features |
| `installRootPackages` | string | — | Extra packages at build time (root) |
| `prebuildDefaultPackage` | string | — | Run `nix-build default.nix` on startup |
| `prebuildNixShell` | string | — | Run `nix-build shell.nix` on startup |
| `prebuildFlake` | string | — | Run `nix build <URI>` on startup |
| `prebuildFlakeRun` | string | — | Run `nix run <URI>` on startup |
| `prebuildFlakeDevelop` | string | — | Run `nix develop <URI>` on startup |
| `additionalNixChannel` | string | — | Extra channels: `name=url,...` |
| `additionalNixFlakeRegistry` | string | — | Extra flake registries: `name=uri,...` |
| `prebuildHomeManager` | string | — | Activate home-manager from path |
| `prebuildHomeManagerFlake` | string | — | Activate home-manager from flake URI |
| `imageVariant` | string | `v1` | Which published image tag to use |

Template scripts are split into:
- `library-scripts/build/` – run during `docker build` (Dockerfile `RUN` steps)
- `library-scripts/runtime/` – run via `postCreateCommand` after container starts

## Git Branching Model

Defined in `DEVELOPMENT.md`:

| Branch | Purpose |
|---|---|
| `main` | Stable, tested, buildable |
| `develop` | Latest/bleeding edge |
| `channel-<version>` | Fixes for a specific Nix channel version |
| `v<semver>` | Orchestration versions (templates, workflows) |

**Do not push directly to `main` or `develop`** without a PR. Branches used by CI must be buildable.

## Image Tagging Convention

| Tag pattern | Meaning |
|---|---|
| `stable` / `main` | Built from `main` branch |
| `latest` / `develop` | Built from `develop` branch |
| `<component>--<version>` | e.g. `flake--latest`, `flake--nixos-25.05` |
| `---<cal-ver>` / `---v<sem-ver>` | Canonical tag from the git tag |
| `base--<channel>` | Base image for a specific Nix channel |
| `base--<channel>---<arch>` | Arch-specific base image manifest |

## CI/CD Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| `build-base.yaml` | Push/PR to `main`/`develop`, `v*` tags | Builds base Nix images via flake for x86_64 + aarch64; creates multi-arch manifest |
| `build-push-latest.yaml` | Push/PR to `main`/`develop`, `v*` tags | Builds and pushes the main devcontainer image (both channel variants) |
| `build-push-latest-flake.yaml` | Same | Flake variant of the main image |
| `build-push-latest-nixos.yaml` | Same | NixOS experimental image |
| `build-push-latest-nixos-arion.yaml` | Same | NixOS-arion image |
| `release.yaml` | Manual dispatch | Publishes devcontainer templates to GHCR; auto-generates README docs via PR |
| `test-pr.yaml` | Any PR | Detects changed templates; runs smoke tests |

### CI Conventions

- GitHub Actions workflows use matrix strategy over Nix channels (`nixos-25.05`, `nixos-unstable`) and architectures (`x86_64-linux`, `aarch64-linux`).
- Nix flake cache is provided by `DeterminateSystems/flakehub-cache-action`.
- Images are only pushed when the PR is from the same repo (not forks), preventing secrets leakage.
- Workflow action versions are pinned by SHA for security.

## Key Conventions for AI Assistants

1. **Prefer Nix over shell commands** when adding packages or build steps. Follow the priority rules in `DEVELOPMENT.md`:
   - Nix build → Nix in Dockerfile → Nix-based base image → imperative fallback

2. **Pin dependencies** – use `flake.lock` to pin flake inputs; never leave channels unpinned in production code.

3. **Environment variables via direnv** – configuration is injected through `.envrc` / `.local.envrc` / `.local.env`, not hardcoded.

4. **Do not modify `flake.lock` manually** – update it with `nix flake update` or let Renovate handle it.

5. **Separate build-time vs runtime scripts** – template scripts must go in `library-scripts/build/` (Dockerfile `RUN`) or `library-scripts/runtime/` (`postCreateCommand`), not mixed.

6. **Image tag format matters** – follow the `<component>--<version>---<cal-or-sem-ver>` tagging convention when adding new image variants.

7. **Non-root by default** – the devcontainer user is `vscode` (UID 1000). Root-only operations must be done in the root block of the Dockerfile before switching to `USER ${USERNAME}`.

8. **nix.conf** – experimental features (`nix-command flakes`) are enabled by default. The `trusted-users` list includes `vscode`, `@wheel`, `@admin`.

9. **Template docs are auto-generated** – `templates/src/nix/README.md` is generated from `devcontainer-template.json` by the release workflow. Edit `devcontainer-template.json`, not the README directly.

10. **Renovate** is configured to auto-update `flake.lock` and base config — do not disable it.
