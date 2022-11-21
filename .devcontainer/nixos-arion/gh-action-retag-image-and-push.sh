#!/usr/bin/env bash
# tag a source image into a multiple docker tag
# tags from GH action are separated by comma

echo "input tags: $1"

for tag in ${1//,/ }
do
    echo "processing tag: $tag"
    docker tag ghcr.io/lucernae/devcontainer-nix:nixos-arion $tag
    docker push $tag
done