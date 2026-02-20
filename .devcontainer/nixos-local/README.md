# NixOS Devcontainer - Local Test

This directory contains a devcontainer configuration to test the pre-built NixOS image from GHCR.

## Usage

### Option 1: VS Code

1. Open this repository in VS Code
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
3. Type "Dev Containers: Open Folder in Container"
4. Select `.devcontainer/nixos-local`

### Option 2: Command Line with Devcontainer CLI

```bash
devcontainer up --workspace-folder . --config .devcontainer/nixos-local/devcontainer.json
```

### Option 3: Docker Compose (Manual)

```bash
cd .devcontainer/nixos-local
docker-compose up -d
docker-compose exec devcontainer bash
```

## Image Details

- **Source**: `ghcr.io/lucernae/devcontainer-nix:nixos--nixos-25.11`
- **Architecture**: Multi-arch (x86_64-linux, aarch64-linux)
- **Channel**: nixos-25.11
- **Features**:
  - Full NixOS system with systemd
  - Nix flakes support
  - Docker client
  - Pre-configured with vscode user

## Testing Checklist

Once inside the container, verify:

```bash
# Check NixOS version
nixos-version

# Check Nix version
nix --version

# Check systemd is running
systemctl status

# Test Docker
docker --version

# Check vscode user exists
id vscode

# Test Nix flakes
nix flake --help
```

## Troubleshooting

### Container fails to start

Make sure you're running in privileged mode and have cgroup v2 support:

```bash
docker info | grep -i cgroup
```

### Permission denied errors

The container runs as root by default for NixOS initialization. The `vscode` user is available for development work.

### Image not found

If the image is not found, it may not have been pushed yet. Check the GitHub Actions workflow status or run:

```bash
docker pull ghcr.io/lucernae/devcontainer-nix:nixos--nixos-25.11
```
