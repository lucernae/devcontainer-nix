#!/usr/bin/env bash

# make docker socket accessible to containers
sudo chown root:vscode /var/run/docker.sock
docker buildx install

./entrypoint.sh "${@:1}"