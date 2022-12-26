#!/usr/bin/env bash

if [[ -n "${PREBUILD_FLAKE_DEVELOP}" ]]; then
    echo "prebuilding flake develop"
    nix develop "${PREBUILD_FLAKE_DEVELOP}" --command echo "prebuilding flake develop done"
fi