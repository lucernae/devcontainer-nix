#!/usr/bin/env bash

# make docker socket accessible to containers
sudo chown root:vscode /var/run/docker.sock
docker buildx install

if [[ -z "$1" ]]; then
    echo "Target directory: $1"
    cd $1
fi

if [[ -f .envrc ]]; then
    echo "Activating direnv"
    . ~/.nix-profile/etc/profile.d/nix.sh
    direnv allow ./.envrc
    direnv exec . "${@:2}"
fi

exec "${@:2}"