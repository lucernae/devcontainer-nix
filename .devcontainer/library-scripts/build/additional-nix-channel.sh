#!/usr/bin/env bash

prevIFS=$IFS

# Ensure default nixpkgs channel exists
if ! nix-channel --list | grep -q "nixpkgs"; then
    echo "Adding default nixpkgs channel"
    nix-channel --add https://nixos.org/channels/nixpkgs-23.05 nixpkgs
    nix-channel --update
fi

# Add additional channels if specified
if [[ -n "${ADDITIONAL_NIX_CHANNEL}" ]]; then
    echo "Add extra nix channel"
    nix --version
    nix-channel --list

    # Retrieve channels
    IFS=","
    read -a channels<<<"${ADDITIONAL_NIX_CHANNEL}"
    for channel in "${channels[@]}"; do
        IFS="="
        read name url <<< $channel
        echo "Will add $name $url"
        nix-channel --add $url $name
    done

    nix-channel --update
fi
IFS=$prevIFS