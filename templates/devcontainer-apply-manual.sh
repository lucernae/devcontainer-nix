#!/usr/bin/env bash
devcontainer templates apply -t ghcr.io/lucernae/devcontainer-nix/nix:1 --workspace-folder ../tmp  -a "$(cat ../tmp/args.json)"