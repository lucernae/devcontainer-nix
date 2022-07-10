#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "Target directory: $1"
    cd $1
fi

if [[ -f .envrc ]]; then
    echo "Activating direnv"
    . ~/.nix-profile/etc/profile.d/nix.sh
    direnv allow ./.envrc
    ls -al /vscode/vscode-server
    direnv exec . "${@:2}"
fi

exec "${@:2}"