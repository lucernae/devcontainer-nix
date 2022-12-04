#!/usr/bin/env bash

if [[ -n "${PREBUILD_HOME_MANAGER}" ]]; then
    echo "prebuilding home-manager"
    if ! command -v home-manager &>/dev/null; then
        echo "home-manager not found, attempting to install"
        if [[ "${USE_FLAKE}" == "true" ]]; then
            nix profile install nixpkgs#home-manager
        else
            if ! nix-channel --list | grep home-manager &>/dev/null; then
                nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
                nix-channel --update
            fi
            nix-shell '<home-manager>' -A install
        fi
    else
        echo "home-manager already exists"
    fi
fi