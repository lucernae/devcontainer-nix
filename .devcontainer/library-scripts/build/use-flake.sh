#!/usr/bin/env bash

if [[ "${USE_FLAKE}" == "true" ]]; then
    echo "Use Flake mode is activated"
    echo "Upgrading Nix to latest release"
    nix --version

    # Check for existing channel collision
    if nix-channel --list | grep -q "nixpkgs"; then
        # Remove any duplicate nixpkgs channels to avoid collision
        current_channels=$(nix-channel --list | grep "nixpkgs" | wc -l)
        if [ "$current_channels" -gt "1" ]; then
            echo "Removing duplicate nixpkgs channels to avoid collision"
            # Keep only the user's nixpkgs channel, remove root's if it exists
            if [ -e /root/.nix-channels ] && [ -e /home/vscode/.nix-channels ]; then
                grep -v "nixpkgs" /root/.nix-channels > /tmp/root-channels
                mv /tmp/root-channels /root/.nix-channels
            fi
        fi
    else
        # Add nixpkgs channel only if no nixpkgs channel exists
        nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
        nix-channel --update || echo "Channel update failed, continuing anyway"
    fi

    # Use nix profile instead of nix-env for Nix 2.4+
    nix_version=$(nix --version | grep -oP '\d+\.\d+' | head -1)
    if (( $(echo "$nix_version >= 2.4" | bc -l) )); then
        echo "Using nix profile for Nix $nix_version"
        nix profile install nixpkgs#nix nixpkgs#cacert || echo "Failed to install with nix profile, falling back to nix-env"
        if [ $? -ne 0 ]; then
            # Fallback to nix-env only if nix profile fails
            nix-env -iA nixpkgs.nix nixpkgs.cacert || echo "Failed to install packages, continuing anyway"
        fi
    else
        # Use nix-env for older versions
        nix-env -iA nixpkgs.nix nixpkgs.cacert || echo "Failed to install packages, continuing anyway"
    fi
    
    nix --version

    echo "Will attempt to install packages using Nix Flake commands"
    flags=('nix-command' 'flakes')
    experimentalFeaturesEnabled="$(grep "experimental-features" /etc/nix/nix.conf || true)"
    if [[ -z "$experimentalFeaturesEnabled" ]]; then
        echo "experimental-features = " >> /etc/nix/nix.conf
    fi
    for flag in "${flags[@]}"; do
        flagExists="$(grep "^experimental-features\s*=.*$flag" /etc/nix/nix.conf || true)"
        if [[ -z "$flagExists" ]]; then
            sed -i "s/^experimental-features\s*=.*/& $flag/" /etc/nix/nix.conf
        fi
    done
fi