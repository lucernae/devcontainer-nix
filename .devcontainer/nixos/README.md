# NixOS Devcontainer (Experimental)

This devcontainer provides a **full NixOS environment** running inside a container with **systemd as PID 1**. Unlike the standard Nix-based devcontainer, this setup allows you to use NixOS modules, declarative system configuration, and systemd services.

## Overview

This experimental setup addresses the challenge of integrating NixOS-built images with VS Code's devcontainer workflow. Instead of requiring images to be pre-built and pushed to a registry, this approach uses **pure Nix** to build the container image:

1. Uses **`flake.nix`** and **`dockerTools.buildLayeredImage`** to build a NixOS OCI image
2. Evaluates `configuration.nix` to generate a complete NixOS system
3. Runs systemd as PID 1, providing a full NixOS environment
4. Allows editing `configuration.nix` and rebuilding via Nix commands locally

**Note**: The Dockerfile method is being phased out in favor of pure Nix builds using flakes.

## Migration from Dockerfile to Nix Builds

If you were previously using the Dockerfile-based build:

**Old workflow**:
```bash
docker-compose -f docker-compose.build.yml build
docker-compose up -d
```

**New workflow**:
```bash
nix build .#layeredImage
docker load < result
docker-compose up -d
```

**Key changes**:
- ✅ No more `docker-compose.build.yml` needed
- ✅ Faster rebuilds (Nix caching vs Docker layer caching)
- ✅ Reproducible builds via `flake.lock`
- ✅ Configuration stays in `configuration.nix` (no changes needed)
- ⚠️ Requires Nix installed on the host machine
- ⚠️ VS Code "Rebuild Container" won't work (use Nix build instead)

**Compatibility note**: The `Dockerfile` still exists for backward compatibility but is no longer maintained. All new features will be added to the Nix-based build only.

## Why Pure Nix Builds?

Traditional Docker-based devcontainers use a `Dockerfile` with imperative `RUN` commands. This setup uses **declarative Nix expressions** instead:

| Traditional Dockerfile | Pure Nix Build |
|------------------------|----------------|
| `FROM base-image` | `fromImage = baseImage` (Nix derivation) |
| `RUN nix-build ...` | `nix build .#layeredImage` (outside Docker) |
| `COPY --from=stage ...` | `copyToRoot = pkgs.buildEnv { paths = [...] }` |
| `RUN /activate` | `runAsRoot = "${container}/activate"` |
| Layer invalidation on any change | Per-package layer caching |
| Sequential multi-stage builds | Parallel Nix builds |
| Requires Docker daemon | Can build without Docker (nix2container) |

**Benefits**:
- ✅ **Reproducible**: `flake.lock` pins all inputs (nixpkgs, tools, etc.)
- ✅ **Fast iterations**: Nix only rebuilds changed derivations
- ✅ **Better caching**: Each package = separate layer
- ✅ **Declarative**: Everything is a Nix expression
- ✅ **CI-friendly**: `nix build` works anywhere Nix runs

## Quick Start

### Prerequisites

- **Nix with flakes enabled** (required for building images)
- Docker and Docker Compose (for running containers)
- VS Code with Remote-Containers extension (for devcontainer integration)

To enable flakes in Nix, add to `~/.config/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

### Launch the Devcontainer

**Method 1: Build via Nix Flake (Recommended)**

```bash
# Build the layered image
nix build .#layeredImage

# Load into Docker
docker load < result

# Start the container
docker-compose up -d
```

**Method 2: Use Pre-built Image in VS Code**

1. Open this directory in VS Code
2. Run **"Dev Containers: Reopen in Container"** from the command palette
3. Wait for systemd to finish booting
4. The `postCreateCommand` script will run to complete setup

## Directory Structure

```
.devcontainer/nixos/
├── flake.nix                      # Flake definition - main entry point for builds
├── flake.lock                     # Pinned flake inputs (nixpkgs, nix2container, etc.)
├── devcontainer.json              # VS Code devcontainer configuration
├── docker-compose.yml             # Compose file for running the container
├── nix.conf                       # Nix configuration (experimental features enabled)
│
├── etc/nixos/
│   ├── configuration.nix          # NixOS system configuration (THE MAIN CONFIG FILE)
│   └── devcontainer-patch.nix     # VS Code compatibility libraries derivation
│
├── opt/devcontainer/scripts/
│   └── post-create.sh             # Post-creation setup (systemd wait, D-Bus, channels)
│
├── container-definition.nix       # Evaluates configuration.nix → NixOS system derivation
├── container-layeredImage.nix     # Builds OCI image via dockerTools.buildLayeredImage
├── container-nix2container.nix    # Alternative: nix2container for registry push
├── container-tarball.nix          # Legacy: tarball format (used by deprecated Dockerfile)
│
├── Dockerfile                     # DEPRECATED: Being phased out
└── docker-compose.build.yml       # DEPRECATED: For Dockerfile builds only
```

## Configuration

### Customizing `configuration.nix`

The main system configuration is in **`etc/nixos/configuration.nix`**. This is a standard NixOS configuration module where you can:

#### Add System Packages

```nix
environment.systemPackages = with pkgs; [
  vim
  git
  nodejs
  python3
  # Add your packages here
];
```

#### Enable Services

```nix
services.postgresql.enable = true;
services.postgresql.package = pkgs.postgresql_15;

services.redis.servers."myredis" = {
  enable = true;
  port = 6379;
};
```

#### Configure Systemd Services

```nix
systemd.services.my-service = {
  description = "My Custom Service";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.my-package}/bin/my-command";
    Restart = "always";
  };
};
```

#### Modify User Settings

The default user is `vscode` (UID 1000) with sudo privileges:

```nix
users.users.vscode = {
  uid = 1000;
  isNormalUser = true;
  home = "/home/vscode";
  group = "vscode";
  extraGroups = [ "wheel" "docker" ];
  # Add more groups or settings
};
```

### Rebuilding After Configuration Changes

After modifying `configuration.nix`, rebuild the image using Nix:

**Option 1: Rebuild via Nix Flake (Recommended)**

```bash
# Rebuild the layered image
nix build .#layeredImage --rebuild

# Load into Docker (this will create a new image)
docker load < result

# Stop old container and start new one
docker-compose down
docker-compose up -d
```

**Option 2: VS Code Rebuild**

VS Code's "Rebuild Container" will use the Dockerfile (deprecated) or pull a pre-built image. For local development with configuration changes, **use the Nix flake method above**.

**Option 3: Quick Iteration with nix2container**

For faster iteration during development:

```bash
# Build with nix2container (doesn't need Docker daemon)
nix build .#nix2ContainerImage

# Copy to Docker (if you have nix2container tools)
./result/bin/nix2container-copy-to-docker
```

### Using `nixos-rebuild` Inside the Container

Once inside the container, you can also use `nixos-rebuild` to apply changes:

```bash
# Edit the configuration (copied to /etc/nixos/bootstrap-configuration.nix at build time)
sudo vi /etc/nixos/configuration.nix

# Test the new configuration
sudo nixos-rebuild test

# Apply and make it permanent
sudo nixos-rebuild switch
```

**Note**: Changes made with `nixos-rebuild` inside the container are **ephemeral** unless you also update `etc/nixos/configuration.nix` in your source and rebuild the image.

## Setting Up home-manager

home-manager allows you to declaratively manage your user environment (dotfiles, shell config, packages, etc.) using Nix.

### Method 1: Standalone home-manager (Recommended for Devcontainers)

1. **Create a `home.nix` in your workspace** (e.g., `.devcontainer/nixos/home.nix`):

```nix
{ config, pkgs, ... }:

{
  # Specify the home-manager release version
  home.stateVersion = "25.11";

  # User packages
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    eza
    starship
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "you@example.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # Zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "docker" "kubectl" ];
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$all";
    };
  };

  # Direnv integration
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
```

2. **Initialize home-manager in the container**:

After the container starts, run:

```bash
# Switch to the vscode user if running as root
su - vscode

# Initialize home-manager with your config
home-manager switch -f /workspace/.devcontainer/nixos/home.nix
```

3. **Make it automatic** by adding to `opt/devcontainer/scripts/post-create.sh`:

```bash
# Add near the end of the script
if [ -f /workspace/.devcontainer/nixos/home.nix ]; then
  echo "[devcontainer-nix] Activating home-manager configuration..."
  su - vscode -c "home-manager switch -f /workspace/.devcontainer/nixos/home.nix"
fi
```

### Method 2: NixOS Module Integration

Integrate home-manager as a NixOS module in `configuration.nix`:

1. **Add home-manager to the configuration**:

```nix
{ config, pkgs, ... }:

{
  # ... existing configuration ...

  # Import home-manager module
  imports = [ <home-manager/nixos> ];

  # Configure home-manager for the vscode user
  home-manager.users.vscode = { pkgs, ... }: {
    home.stateVersion = "25.11";

    home.packages = with pkgs; [
      ripgrep
      fd
      bat
    ];

    programs.git = {
      enable = true;
      userName = "Your Name";
      userEmail = "you@example.com";
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
    };
  };
}
```

2. **Rebuild the container** to apply changes.

### Method 3: Flake-based home-manager

For flake-based setups, create a `flake.nix` in your workspace:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }: {
    homeConfigurations."vscode" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./home.nix ];
    };
  };
}
```

Then activate:

```bash
home-manager switch --flake .#vscode
```

## Development Workflows

### Local Image Development (Pure Nix)

Build and test the NixOS image using only Nix (no Dockerfile):

```bash
# Enter the development shell (optional, for tools)
nix develop

# Build the layered image
nix build .#layeredImage

# Load into Docker
docker load < result

# Start the container
docker-compose up -d

# Access the container
docker-compose exec devcontainer bash
```

### Build Outputs Available

The flake provides multiple build outputs:

```bash
# Standard layered image (uses dockerTools.buildLayeredImage)
nix build .#layeredImage

# nix2container variant (for pushing to registry without Docker)
nix build .#nix2ContainerImage

# Base image (just Debian libs for VS Code compatibility)
nix build .#baseImage
```

### Iterative Development Workflow

```bash
# 1. Edit configuration.nix
vim etc/nixos/configuration.nix

# 2. Rebuild the image
nix build .#layeredImage --rebuild

# 3. Reload into Docker
docker load < result

# 4. Recreate container
docker-compose down && docker-compose up -d

# 5. Test your changes
docker-compose exec devcontainer systemctl status
```

### Accessing the Container

```bash
# As root (default)
docker-compose exec devcontainer bash

# As vscode user
docker-compose exec devcontainer su - vscode

# Run systemctl commands
docker-compose exec devcontainer systemctl status
```

### Checking Systemd Services

```bash
# List all services
systemctl list-units --type=service

# Check a specific service
systemctl status nix-daemon

# View logs
journalctl -u nix-daemon -f
```

### Adding Nix Channels

Nix channels are managed per-user. To add additional channels:

```bash
# As root
sudo nix-channel --add https://nixos.org/channels/nixos-unstable unstable
sudo nix-channel --update

# As vscode user
nix-channel --add https://nixos.org/channels/nixos-unstable unstable
nix-channel --update
```

Or configure them declaratively in `configuration.nix`:

```nix
nix.settings.substituters = [
  "https://cache.nixos.org"
  "https://nix-community.cachix.org"
];

nix.settings.trusted-public-keys = [
  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
];
```

## Build Process Explained (Nix Flake + dockerTools)

The build process uses **pure Nix** with `dockerTools.buildLayeredImage` to create the OCI image. Here's how it works:

### Step 1: Evaluate NixOS Configuration (`container-definition.nix`)

```nix
container = (import (pkgs.path + "/nixos/lib/eval-config.nix") {
  inherit system;
  modules = [
    ./configuration.nix                          # Your custom config
    (pkgs.path + "/nixos/modules/profiles/minimal.nix")  # Minimal profile
  ];
}).config.system.build.toplevel;
```

This produces a NixOS system derivation with all packages, services, and activation scripts.

### Step 2: Extract VS Code Compatibility Libraries (`container-layeredImage.nix`)

VS Code Remote Server requires real Debian libraries (not NixOS equivalents):

```nix
microsoftBaseImage = pkgs.dockerTools.pullImage {
  imageName = "mcr.microsoft.com/devcontainers/base";
  # Extract /lib, /lib64, /usr/lib from Microsoft's base image
};

debianLibsForVSCode = pkgs.runCommand "debian-libs-vscode" {
  # Extract libraries from the pulled image layers
  # Copies to $out/lib, $out/lib64, $out/usr/lib
};
```

### Step 3: Build Layered Base Image

```nix
baseLayeredImage = pkgs.dockerTools.buildLayeredImage {
  name = "ghcr.io/lucernae/devcontainer-nix-base";
  tag = "rootfs-build";
  contents = [ debianLibsForVSCode ];
};
```

This creates a multi-layer image with better caching. Each dependency gets its own layer, so unchanged packages don't need to be re-downloaded.

### Step 4: Build Final Image with NixOS Activation

```nix
layeredImage = pkgs.dockerTools.buildImage {
  name = "ghcr.io/lucernae/devcontainer-nix";
  tag = "nixos-dockertools";
  fromImage = baseLayeredImage;

  copyToRoot = pkgs.buildEnv {
    paths = [ configFiles postCreateScript ];
  };

  runAsRoot = ''
    ${container}/activate || true  # Run NixOS activation script
  '';

  config = {
    Cmd = [ "${container}/init" ];  # systemd init
    Env = [ "PATH=/run/wrappers/bin:/bin:/usr/bin:..." ];
  };
};
```

This:
- Builds on top of the base image (inherits Debian libs)
- Adds your `configuration.nix` and post-create scripts
- **Runs the NixOS activation script** at image build time to set up symlinks (`/bin`, `/usr/sbin/init`, etc.)
- Sets systemd as the container's init process

### Why This Approach?

| Aspect | Pure Nix Build | Dockerfile Build |
|--------|----------------|------------------|
| **Reproducibility** | ✅ Fully hermetic with `flake.lock` | ⚠️ Depends on base image tags |
| **Caching** | ✅ Per-package layer caching | ⚠️ Layer invalidation on any change |
| **Build Speed** | ✅ Parallel Nix builds | ⚠️ Sequential Docker stages |
| **Declarative** | ✅ Pure Nix expressions | ⚠️ Imperative shell commands |
| **VS Code Integration** | ⚠️ Requires manual load | ✅ Native rebuild support |
| **Iteration Speed** | ✅ Nix incremental builds | ⚠️ Full Docker rebuild |

**Result**: The Nix approach provides better reproducibility and faster iteration for development.

## Quick Reference

### Common Commands

```bash
# Build the image
nix build .#layeredImage

# Load into Docker
docker load < result

# Start container
docker-compose up -d

# Access container as root
docker-compose exec devcontainer bash

# Access as vscode user
docker-compose exec devcontainer su - vscode

# Check systemd status
docker-compose exec devcontainer systemctl status

# Rebuild after config changes
nix build .#layeredImage --rebuild && docker load < result && docker-compose down && docker-compose up -d

# View container logs
docker-compose logs -f
```

## Key Files Reference

### Core Nix Build Files (Active)

#### `flake.nix`
The main entry point. Defines:
- Inputs: `nixpkgs`, `nix2container`, `flake-utils`
- Outputs: `layeredImage`, `nix2ContainerImage`, `baseImage`
- Multi-architecture support via `flake-utils`

#### `container-definition.nix`
Evaluates `etc/nixos/configuration.nix` using NixOS's `eval-config.nix` to produce a system derivation. This is the bridge between your declarative config and the NixOS system closure.

#### `container-layeredImage.nix`
The main build logic:
1. Pulls Microsoft devcontainer base image for Debian libraries
2. Extracts libraries needed by VS Code Remote Server
3. Creates `baseLayeredImage` with compatibility libs
4. Creates final `layeredImage` with NixOS system + activation
5. Outputs an OCI image loadable with `docker load`

#### `container-nix2container.nix`
Alternative build using `nix2container.buildImage`:
- Doesn't require Docker daemon
- Can push directly to registry
- More efficient for CI/CD pipelines

#### `etc/nixos/configuration.nix`
**THE MAIN CONFIG FILE**. Standard NixOS configuration module where you define:
- System packages
- Systemd services
- Users and groups
- Network settings
- Boot configuration

#### `etc/nixos/devcontainer-patch.nix`
Derivation providing VS Code compatibility shims:
- `libstdc++.so.6` for Node.js
- `libgcc_s.so.1`, `libdl.so.2` for glibc
- Dynamic linker symlinks (`ld-linux-*.so.*`)
- Multi-arch support (x86_64 and aarch64)

#### `opt/devcontainer/scripts/post-create.sh`
Runs after the container starts (via `postCreateCommand` in devcontainer.json):
1. Waits for systemd to reach "running" or "degraded" state
2. Starts D-Bus (required for `nixos-rebuild` and other tools)
3. Updates Nix channels for root and the current user

### Deprecated Files

#### `container-tarball.nix`
Legacy format used by the deprecated Dockerfile. Wraps the NixOS system into a tarball.

#### `Dockerfile`
**DEPRECATED**. Multi-stage build using imperative shell commands. Being phased out in favor of declarative Nix builds.

#### `docker-compose.build.yml`
**DEPRECATED**. Only used for Dockerfile-based builds.

## Troubleshooting

### Nix build fails with "evaluation error"

**Symptom**: `nix build .#layeredImage` fails with Nix evaluation errors

**Solutions**:
- Check syntax in `configuration.nix`: `nix-instantiate --parse etc/nixos/configuration.nix`
- Verify flake inputs are updated: `nix flake update`
- Check the build log: `nix build .#layeredImage --show-trace`
- Ensure experimental features are enabled: `nix-config | grep experimental-features`

### Nix build fails with "hash mismatch"

**Symptom**: Docker image pull fails with `hash mismatch for ...`

**Cause**: The Microsoft devcontainer base image changed

**Solution**: Update the hash in `container-layeredImage.nix`:

```bash
# Calculate new hash
nix-prefetch-docker mcr.microsoft.com/devcontainers/base ubuntu

# Update sha256 in container-layeredImage.nix
```

### `docker load` doesn't update the image

**Symptom**: After `docker load < result`, changes don't appear

**Cause**: Docker caches old image tags

**Solution**:
```bash
# Remove old images
docker images | grep devcontainer-nix | awk '{print $3}' | xargs docker rmi -f

# Load new image
docker load < result

# Verify new image ID
docker images | grep devcontainer-nix
```

### Container fails to start

**Symptom**: Container exits immediately after `docker-compose up`

**Solutions**:
- Check if Docker has enough resources (CPU, memory)
- Look at container logs: `docker-compose logs`
- Verify systemd is running: `docker-compose exec devcontainer systemctl status`
- Check activation script succeeded: `docker-compose logs | grep activate`

### Systemd services not starting

**Symptom**: Services defined in `configuration.nix` don't start

**Solutions**:
- Check service status: `systemctl status <service>`
- View logs: `journalctl -u <service> -f`
- Ensure the service is enabled in `configuration.nix`:
  ```nix
  systemd.services.my-service.wantedBy = [ "multi-user.target" ];
  ```
- Verify service dependencies are met

### Nix builds fail with "permission denied" on `/tmp`

**Symptom**: Nix builds inside container fail with `/tmp` permission errors

**Solutions**:
- Ensure `/tmp` has correct ACLs: `sudo setfacl -k /tmp`
- This is handled by `post-create.sh` but may need manual intervention
- Check if systemd has properly mounted `/tmp`

### home-manager fails

**Symptom**: `home-manager switch` fails with errors

**Solutions**:
- Ensure you're running as the correct user (not root)
- Check that home-manager channel is added: `nix-channel --list`
- Update channels: `nix-channel --update`
- Verify `home.stateVersion` matches NixOS version

### Changes to configuration.nix don't appear

**Symptom**: Edited `configuration.nix` but nothing changed in container

**Cause**: You must **rebuild the image** for changes to take effect

**Solution**:
```bash
nix build .#layeredImage --rebuild
docker load < result
docker-compose down && docker-compose up -d
```

**Note**: Changes made via `nixos-rebuild` inside the container are ephemeral unless also applied to the source `configuration.nix`.

### VS Code extensions not working

**Symptom**: Extensions fail to activate or show errors

**Solutions**:
- Some extensions require specific libraries; add them to `environment.systemPackages`
- Check extension logs in VS Code Output panel
- Verify VS Code remote server libraries are present:
  ```bash
  ls -la /lib/libstdc++.so.6
  ls -la /lib64/ld-linux-x86-64.so.2
  ```
- Rebuild with updated `devcontainer-patch.nix` if libraries are missing

### Flake inputs are outdated

**Symptom**: Packages are old versions or features are missing

**Solution**:
```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Rebuild with updated inputs
nix build .#layeredImage
```

## Advanced Topics

### Using Flakes for the NixOS Configuration

The current `flake.nix` uses `container-definition.nix` to evaluate `configuration.nix`. You can extend this to use flake-based NixOS configurations:

**Modify `flake.nix`**:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { nixpkgs, ... }: {
    # Define NixOS system configuration in the flake
    nixosConfigurations.devcontainer = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./etc/nixos/configuration.nix
        # Additional modules
      ];
    };

    # Export the system closure for building
    packages.x86_64-linux.system =
      self.nixosConfigurations.devcontainer.config.system.build.toplevel;
  };
}
```

**Update `container-layeredImage.nix`**:

```nix
let
  # Use flake output instead of manual eval
  flake = builtins.getFlake (toString ./.);
  container = flake.packages.${system}.system;
in
# ... rest of the file
```

### Customizing the System for Different Architectures

The flake supports multi-architecture builds via `flake-utils`:

```bash
# Build for x86_64
nix build .#packages.x86_64-linux.layeredImage

# Build for aarch64 (ARM)
nix build .#packages.aarch64-linux.layeredImage
```

To add architecture-specific configuration:

```nix
# In configuration.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim
    git
  ] ++ (if pkgs.stdenv.isAarch64 then [
    # ARM-specific packages
  ] else [
    # x86_64-specific packages
  ]);
}
```

### Understanding Build Variants

The flake provides three build targets:

#### 1. `layeredImage` (Recommended for local development)

```bash
nix build .#layeredImage
docker load < result
```

- Uses `dockerTools.buildLayeredImage` + `buildImage`
- Creates multi-layer OCI image for better caching
- Each package gets its own layer
- Compatible with `docker load`

#### 2. `nix2ContainerImage` (For registry push)

```bash
nix build .#nix2ContainerImage
```

- Uses `nix2container.buildImage`
- Doesn't require Docker daemon
- Can push directly to registry
- More efficient layer sharing
- Requires `nix2container` tools to load into Docker

#### 3. `baseImage` (Just compatibility libraries)

```bash
nix build .#baseImage
```

- Contains only Debian libraries for VS Code
- Used as base layer for `layeredImage`
- Useful for debugging VS Code remote server issues

### Caching Nix Builds

To speed up builds, use a Nix binary cache:

**Option 1: Configure in `nix.conf`**:

```nix
# Add to ~/.config/nix/nix.conf or /etc/nix/nix.conf
substituters = https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
```

**Option 2: Use [Cachix](https://cachix.org)**:

```bash
nix-env -iA cachix -f https://cachix.org/api/v1/install
cachix use nix-community

# Or create your own cache
cachix authtoken <your-token>
cachix create mycache
cachix use mycache
```

**Option 3: Configure per-project** in `flake.nix`:

```nix
{
  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };
}
```

## Understanding the Flake Structure

The `flake.nix` defines build outputs via `flake-utils.lib.eachDefaultSystem`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix2container.url = "github:nlewo/nix2container";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, nix2container, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages = {
        layeredImage = ...;        # dockerTools build
        nix2ContainerImage = ...;  # nix2container build
        baseImage = ...;           # VS Code libs only
      };
    });
}
```

### Extending the Flake

**Add custom packages to the NixOS system**:

Edit `etc/nixos/configuration.nix` (not the flake itself):

```nix
environment.systemPackages = with pkgs; [
  # Your packages here
];
```

**Add additional flake outputs**:

Extend `flake.nix` to export other derivations:

```nix
outputs = { ... }: {
  packages.x86_64-linux = {
    layeredImage = ...;
    nix2ContainerImage = ...;

    # Add custom outputs
    myCustomTool = pkgs.writeShellScriptBin "my-tool" ''
      echo "Hello from custom tool!"
    '';
  };
};
```

Then build with:
```bash
nix build .#myCustomTool
```

## Comparison with Other Setups

| Feature | nixos (this) | nixos-arion | default/development |
|---------|-------------|-------------|---------------------|
| **Base** | Full NixOS | Full NixOS via Arion | Nix package manager only |
| **Init System** | systemd (PID 1) | systemd (PID 1) | No init system |
| **NixOS Modules** | ✅ Yes | ✅ Yes | ❌ No |
| **System Services** | ✅ Full support | ✅ Full support | ⚠️ Manual only |
| **Rebuild Method** | `nix build` + `docker load` | `arion` + compose | Edit `.envrc`/`shell.nix` |
| **Build Tool** | Pure Nix flakes | Arion (Nix + compose) | Docker |
| **Reproducibility** | ✅ Fully hermetic | ✅ Fully hermetic | ⚠️ Channel-based |
| **Complexity** | Medium | High | Low |
| **Build Speed** | ✅ Fast (incremental) | ✅ Fast (incremental) | ⚠️ Sequential Docker |
| **VS Code Integration** | ⚠️ Manual `docker load` | ⚠️ Requires Arion setup | ✅ Native rebuild |
| **Recommended For** | Pure Nix advocates, CI/CD pipelines | Advanced NixOS users | Nix beginners |

**Recommendation**:
- **For learning/simplicity**: Use `default` or `development`
- **For full NixOS with declarative compose**: Use `nixos-arion`
- **For pure Nix builds without Arion**: Use `nixos` (this setup)

## CI/CD Integration

Pure Nix builds excel in CI/CD pipelines:

### GitHub Actions Example

```yaml
name: Build NixOS Devcontainer

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: DeterminateSystems/nix-installer-action@main
        with:
          extra-conf: |
            experimental-features = nix-command flakes

      - uses: DeterminateSystems/magic-nix-cache-action@main

      - name: Build layered image
        run: |
          cd .devcontainer/nixos
          nix build .#layeredImage

      - name: Load and test image
        run: |
          docker load < .devcontainer/nixos/result
          docker run --rm $(docker images -q ghcr.io/lucernae/devcontainer-nix:nixos-dockertools) systemctl --version

      - name: Push to registry (optional)
        if: github.ref == 'refs/heads/main'
        run: |
          echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker push ghcr.io/lucernae/devcontainer-nix:nixos-dockertools
```

### Using nix2container for Registry Push

```yaml
- name: Build with nix2container
  run: |
    nix build .#nix2ContainerImage
    ./result/bin/nix2container-copy-to-docker-daemon

- name: Tag and push
  run: |
    docker tag ghcr.io/lucernae/devcontainer-nix:nixos-dockertools ghcr.io/lucernae/devcontainer-nix:latest
    docker push ghcr.io/lucernae/devcontainer-nix:latest
```

### Benefits in CI

- ✅ **Reproducible**: Same `flake.lock` = same build everywhere
- ✅ **Fast**: Nix binary cache shares builds across CI runs
- ✅ **No Docker layer caching issues**: Nix handles caching internally
- ✅ **Multi-arch builds**: `nix build .#packages.aarch64-linux.layeredImage`
- ✅ **Hermetic**: Doesn't depend on external base images changing

## References

### Nix & NixOS
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Flakes Guide](https://nixos.wiki/wiki/Flakes)
- [nixpkgs Manual - dockerTools](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools)
- [Nix Pills](https://nixos.org/guides/nix-pills/) (in-depth tutorial)

### Related Tools
- [home-manager Manual](https://nix-community.github.io/home-manager/)
- [nix2container](https://github.com/nlewo/nix2container) - Efficient container builds
- [flake-utils](https://github.com/numtide/flake-utils) - Multi-system flake helper

### Devcontainers & VS Code
- [Devcontainer Specification](https://containers.dev/)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)
- [VS Code Devcontainer CLI](https://code.visualstudio.com/docs/devcontainers/devcontainer-cli)

### Examples & Learning
- [nix-docker-examples](https://github.com/NixOS/nixpkgs/tree/master/pkgs/build-support/docker/examples.nix)
- [NixOS containers guide](https://nixos.wiki/wiki/NixOS_Containers)
- [Determinate Systems blog](https://determinate.systems/posts/) - Nix CI/CD best practices

## Contributing

This is an experimental setup. Issues and improvements are welcome! See the main [DEVELOPMENT.md](../../DEVELOPMENT.md) for contribution guidelines.

**Key Areas for Contribution**:
- Optimizing layer caching strategy
- Multi-architecture testing
- Reducing image size
- Improving VS Code compatibility
- Documentation improvements