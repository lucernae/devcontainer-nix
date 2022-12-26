#!/usr/bin/env bash

if [[ -n "${INSTALL_ROOT_PACKAGES}" ]]; then
    echo "Installing root packages"
    sudo su
    if [[ "${USE_FLAKE}" == "true" ]]; then
        nix profile install --priority 4 ${INSTALL_ROOT_PACKAGES}
    else
        nix-env -iA ${INSTALL_ROOT_PACKAGES}
    fi
fi