#!/usr/bin/env bash

if [[ "${USE_FLAKE}" == "true" ]]; then
    echo "Use Flake mode is activated"
    echo "Upgrading nix to latest release"
    nix --version
    nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
    nix-channel --update
    nix-env -iA nixpkgs.nix nixpkgs.cacert
    nix --version
    echo "Will attempt to install packages using Nix Flake commands"
    flags=('nix-command' 'flakes')
    experimentalFeaturesEnabled="$(cat /etc/nix/nix.conf | egrep "experimental-features")"
    if [[ -z "$experimentalFeaturesEnabled" ]]; then
        echo "experimental-features = " >> /etc/nix/nix.conf
    fi
    for flag in "${flags[@]}";
    do
        flagExists="$(cat /etc/nix/nix.conf | egrep "^experimental-features\s*=.*$flag")"
        if [[ -z "$flagExists" ]]; then
            echo "enabling $flag"
            sed -E "s|experimental-features\s*=(.*)$|experimental-features =\1 $flag|g" -i /etc/nix/nix.conf
        else
            echo "$flag already enabled"
        fi
    done
else
    echo "Use Flake mode is deactivated"
    echo "Will attempt to install packages using nix-env commands"
fi