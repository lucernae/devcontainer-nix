#!/usr/bin/env bash

if [[ "${USE_DIRENV}" == "true" ]]; then
    echo "Installing direnv"
    if ! command -v direnv > /dev/null; then
        if [[ "${USE_FLAKE}" == "true" ]]; then
            nix profile install nixpkgs#direnv nixpkgs#nix-direnv
        else
            nix-env -iA nixpkgs.direnv nixpkgs.nix-direnv
        fi
    else
        echo "direnv already exists"
    fi
fi