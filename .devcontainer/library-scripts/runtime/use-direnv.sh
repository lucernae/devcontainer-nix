#!/usr/bin/env bash

if [[ "${USE_DIRENV}" == "true" ]]; then
    echo "Checking direnv config"
    if [[ -f .envrc ]]; then
        echo "Activating direnv"
        direnv allow .
        direnv exec . sleep 1
    fi
fi
