#!/usr/bin/env bash

if [[ -n "${PREBUILD_HOME_MANAGER_FLAKE}" ]]; then
    echo "prebuilding home-manager"
    home-manager switch -b backup --flake "${PREBUILD_HOME_MANAGER_FLAKE}"
fi