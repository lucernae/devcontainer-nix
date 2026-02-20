# NixOS Devcontainer Troubleshooting Guide

## Rule 1: Final Test Procedure

**All final tests MUST use devcontainer CLI and observe until fully loaded.**

```
Goal Condition: FHS is created and observable
- /etc/passwd exists
- /etc/group exists  
- /bin/sh exists
- systemd is running
```

### Test Procedure

```bash
# 1. Clean up any existing containers
docker rm -f nixos-local-devcontainer-1 2>/dev/null

# 2. Run devcontainer CLI
nix-shell -p devcontainer --run "devcontainer up --workspace-folder . --config .devcontainer/nixos-local/devcontainer.json"

# 3. OBSERVE until container is fully loaded:
#    - Wait for "Dev Containers: Finished" or similar success message
#    - Check systemd: docker exec nixos-local-devcontainer-1 systemctl is-system-running
#    - Check FHS: docker exec nixos-local-devcontainer-1 ls -la /etc/passwd /bin/sh

# 4. Goal condition check:
docker exec nixos-local-devcontainer-1 test -f /etc/passwd && echo "✓ /etc/passwd exists"
docker exec nixos-local-devcontainer-1 test -f /etc/group && echo "✓ /etc/group exists"
docker exec nixos-local-devcontainer-1 test -f /bin/sh && echo "✓ /bin/sh exists"
docker exec nixos-local-devcontainer-1 systemctl is-system-running | grep -q running && echo "✓ systemd running"
```

## Rule 2: Proof of Concept First

**When troubleshooting, do NOT wait for GitHub Actions rebuild.**

1. Use existing GHCR image as base
2. Add modifications in local Dockerfile
3. Test locally with devcontainer CLI first
4. Only after POC works, add to container-layeredImage.nix for permanent fix

### Workflow

```
GitHub Actions (permanent fix)  -------->  GHCR Image
       ↑                                    ↑
       |                                    |
       | (after POC works)                 | (for testing)
       |                                    |
       +--------  container-layeredImage  <--+
                          ↑
                          |
                   (add fix here)
                          |
                  docker-compose.yml
                  + Dockerfile (POC)
                          ↓
                   devcontainer CLI
```

## Rule 3: Never Copy Binaries - Use Symlinks from Nix Store

**The base image already has all binaries in the nix store. Never copy binaries - create symlinks instead.**

### Why:
- Copying binaries bloats the image
- Nix store has all needed binaries (bash, coreutils, etc.)
- Just create symlinks to the nix store paths

### Finding Nix Store Paths

```bash
# Find bash in nix store
docker run --rm ghcr.io/lucernae/devcontainer-nix:nixos--nixos-25.11---x86_64-linux \
  find /nix/store -name bash -type f 2>/dev/null | head -5

# Or export and check
docker create --name temp <image>
docker export temp | tar -tf - | grep "bin/bash"
docker rm temp
```

## Rule 4: Original NixOS Systemd Must Be PID 1

**When overriding Docker's entrypoint, the original NixOS systemd entrypoint MUST be PID 1.**

### Why:
- NixOS expects systemd as PID 1
- Systemd handles initialization, services, cgroups
- Blocking the init process breaks the system

### Correct Pattern (Fork and Wait):

```yaml
# WRONG - blocks systemd
entrypoint: ["bash", "-c", "wait_for_ready && /usr/sbin/init"]

# CORRECT - start systemd in background, wait for it
entrypoint: [
  "bash", "-c",
  "/usr/sbin/init &  # start systemd as PID 1
   PID1=$!
   wait_for_vscode_ready
   wait $PID1"
]
```

### Alternative: Use postCreateCommand

Instead of blocking entrypoint, use devcontainer's `postCreateCommand`:

```json
{
  "postCreateCommand": "bash -c 'systemctl is-system-running --wait && echo Ready'"
}
```

This runs AFTER container is created and systemd is already running.

## Problem: VS Code Dev Containers fails to connect

### Error: `unable to find user root: no matching entries in passwd file`

**Root Cause:**
- VS Code runs `uname -m` as a probe to check system architecture
- This requires a valid `/etc/passwd` entry for root
- The NixOS activation hasn't run yet when VS Code tries to connect (systemd hasn't fully started)

### Why this happens:
1. Docker starts container with `/usr/sbin/init` (NixOS init)
2. NixOS init runs activation scripts (creates `/etc/passwd`, `/etc/group`, sets up `/bin/sh`)
3. After activation, systemd starts as PID 1
4. **BUT** VS Code tries to connect BEFORE systemd is ready
5. VS Code needs `/etc/passwd` to run its probe commands

## Solutions

### Solution 1: Add placeholder /etc/passwd in image (Permanent Fix)

The VS Code probe runs BEFORE any devcontainer commands (even `onCreateCommand`). There is no built-in way to delay the probe.

**Therefore, the solution is to add placeholder /etc/passwd and /etc/group to the image at build time.**

Add passwd/group files in the NixOS image build (in container-layeredImage.nix):

```nix
fhsEtc = pkgs.runCommand "fhs-etc" { } ''
  mkdir -p $out/etc
  echo "root:x:0:0:root:/root:/run/current-system/sw/bin/zsh" > $out/etc/passwd
  echo "root:x:0:" > $out/etc/group
  echo "vscode:x:1000:" >> $out/etc/group
'';
```

Include in `contents` array of streamLayeredImage.

### Solution 2: Start container first, then use devcontainer CLI (Workaround)

This is a practical workaround - start the container first, then use devcontainer CLI:

```bash
# 1. Start container with docker-compose
docker compose up -d

# 2. Wait for systemd to boot
sleep 10

# 3. Now run devcontainer CLI - it will attach to running container
devcontainer up --workspace-folder . --config .devcontainer/nixos-local/devcontainer.json
```

This works because:
1. docker-compose starts the container and waits for systemd to boot
2. When systemd is ready, /etc/passwd and /etc/group exist
3. devcontainer CLI then connects to the already-running container
4. VS Code probe succeeds because FHS files exist

### Solution 3: Use entrypoint wrapper (Alternative)

Use a custom entrypoint that waits for systemd (Rule 4):

```yaml
services:
  devcontainer:
    entrypoint: [
      "bash", "-c",
      "/usr/sbin/init &  # start systemd as PID 1
       PID1=$!
       # wait for systemd to be ready
       for i in 1 2 3 4 5 6 7 8 9 10; do
         sleep 2
         if systemctl is-system-running 2>/dev/null | grep -q running; then
           break
         fi
       done
       wait $PID1"
    ]
```

### Solution 2: Add placeholder /etc/passwd to image (Permanent Fix)

Add passwd/group files in the NixOS image build (in container-layeredImage.nix):

```nix
fhsEtc = pkgs.runCommand "fhs-etc" { } ''
  mkdir -p $out/etc
  echo "root:x:0:0:root:/root:/run/current-system/sw/bin/zsh" > $out/etc/passwd
  echo "root:x:0:" > $out/etc/group
  echo "vscode:x:1000:" >> $out/etc/group
'';
```

Include in `contents` array of streamLayeredImage.

**IMPORTANT: DO NOT COPY /etc/ in Dockerfile!**
- Copying /etc/ files to the image will break NixOS activation
- The /etc/ must be generated by NixOS activation at runtime
- Placeholder files must be added at Nix expression level (container-layeredImage.nix)

## Current Status

- ✅ systemd boots correctly with `--cgroupns=host`
- ✅ Nix and NixOS work inside the container  
- ✅ docker-compose works directly with original GHCR image
- ❌ VS Code Dev Containers fails (needs passwd before systemd ready)

## Debugging

```bash
# Check systemd status (must show "running")
docker exec nixos-local-devcontainer-1 systemctl is-system-running

# Check activation logs
docker logs nixos-local-devcontainer-1

# Check FHS files exist
docker exec nixos-local-devcontainer-1 ls -la /etc/passwd
docker exec nixos-local-devcontainer-1 ls -la /etc/group  
docker exec nixos-local-devcontainer-1 ls -la /bin/sh

# Check Nix works
docker exec nixos-local-devcontainer-1 nix --version
docker exec nixos-local-devcontainer-1 nixos-version
```
