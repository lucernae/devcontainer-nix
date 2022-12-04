#!/usr/bin/env bash

if [[ -n "${PREBUILD_HOME_MANAGER}" ]]; then
    echo "prebuilding home-manager"
    home-manager -f "${PREBUILD_HOME_MANAGER}" switch
fi