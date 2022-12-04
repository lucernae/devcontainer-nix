#!/usr/bin/env bash

if [[ -n "${PREBUILD_DEFAULT_PACKAGE}" ]]; then
    echo "prebuilding default package"
    nix-build --no-out-link "${PREBUILD_DEFAULT_PACKAGE}"
fi