#!/usr/bin/env bash

if [[ -n "${PREBUILD_FLAKE}" ]]; then
    echo "prebuilding flake"
    nix build "${PREBUILD_FLAKE}"
fi