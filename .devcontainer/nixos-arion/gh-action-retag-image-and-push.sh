#!/usr/bin/env bash
# tag a source image into a multiple docker tag
# tags from GH action are separated by comma

for tag in ${1//,/ }
do
    docker tag ghcr.io/lucernae/devcontainer-nix:nixos--arion $tag
    docker push $tag
done