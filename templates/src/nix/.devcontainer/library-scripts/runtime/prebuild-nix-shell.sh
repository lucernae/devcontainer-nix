#!/usr/bin/env bash

if [[ -n "${PREBUILD_NIX_SHELL}" ]]; then
    echo "prebuilding nix-shell"
    nix-shell --run "echo 'prebuilding nix-shell done'" "${PREBUILD_NIX_SHELL}"
fi