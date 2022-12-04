#!/usr/bin/env bash

prevIFS=$IFS

if [[ -n "${ADDITIONAL_NIX_FLAKE_REGISTRY}" ]]; then
    echo "Add extra nix channel"
    nix --version
    echo "Registry list:"
    nix registry list
    echo

    # retrieve channels
    IFS="," 
    read -a channels<<<"${ADDITIONAL_NIX_FLAKE_REGISTRY}"
    for channel in "${channels[@]}";
    do
        IFS="="
        read name url <<< $channel
        echo "Will add $name $url"
        nix registry add $name "$url"
    done
    echo
    echo 
    nix registry list
    echo
fi
IFS=$prevIFS