#!/usr/bin/env bash
set -e

# Detect if running as root
CURRENT_USER=$(whoami)
echo "[devcontainer-nix] Running as user: $CURRENT_USER"

# Use sudo prefix for non-root users when accessing systemctl
if [ "$CURRENT_USER" = "root" ]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "[devcontainer-nix] Waiting for systemd to be running..."
until $SUDO systemctl is-system-running --wait 2>/dev/null | grep -E "running|degraded"; do
  echo "[devcontainer-nix] Current systemd state: $($SUDO systemctl is-system-running 2>/dev/null || echo 'unknown')"
  sleep 2
done

echo "[devcontainer-nix] Systemd is ready. Running post-create commands..."

# Ensure D-Bus is running (needed for nixos-rebuild and other system tools)
echo "[devcontainer-nix] Starting D-Bus service..."
$SUDO systemctl start dbus.socket || true
$SUDO systemctl start dbus.service || true

# Handle nix-channel setup based on user
if [ "$CURRENT_USER" = "root" ]; then
  echo "[devcontainer-nix] Running as root - updating root's nix channels..."
  nix-channel --list
  nix-channel --update
else
  echo "[devcontainer-nix] Running as non-root user - copying nix channels from root..."
  # Get root's channel list and add them to current user
  sudo nix-channel --list | while IFS=' ' read -r name url; do
    echo "[devcontainer-nix] Adding channel: $name -> $url"
    nix-channel --add "$url" "$name"
  done

  echo "[devcontainer-nix] Current user channels:"
  nix-channel --list

  echo "[devcontainer-nix] Updating current user's nix channels..."
  nix-channel --update

  echo "[devcontainer-nix] Updating root's nix channels..."
  sudo nix-channel --update
fi

echo "[devcontainer-nix] Post-create setup complete!"
