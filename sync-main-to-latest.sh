#!/usr/bin/env bash

docker tag ghcr.io/lucernae/devcontainer-nix:main ghcr.io/lucernae/devcontainer-nix:latest
docker push ghcr.io/lucernae/devcontainer-nix:latest