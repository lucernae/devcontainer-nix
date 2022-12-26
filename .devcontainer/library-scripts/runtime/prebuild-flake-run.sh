#!/usr/bin/env bash

if [[ -n "${PREBUILD_FLAKE_RUN}" ]]; then
    echo "prebuilding flake run"
    nix run "${PREBUILD_FLAKE_RUN}"
fi