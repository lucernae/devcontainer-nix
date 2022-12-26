#!/usr/bin/env bash

prevIFS=$IFS

if [[ -n "${ADDITIONAL_NIX_CHANNEL}" ]]; then
    echo "Add extra nix channel"
    nix --version
    nix-channel --list

    # retrieve channels
    IFS="," 
    read -a channels<<<"${ADDITIONAL_NIX_CHANNEL}"
    for channel in "${channels[@]}";
    do
        IFS="="
        read name url <<< $channel
        echo "Will add $name $url"
        nix-channel --add $url $name
    done

    nix-channel --update
fi
IFS=$prevIFS