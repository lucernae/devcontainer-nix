#!/usr/bin/env bash

# Reset default ACL on /tmp so that Nix can use proper umask for the Nix build process
sudo setfacl -k /tmp

# Initialize Nix for the root user
if [[ ! -d /root/.nix-profile ]]; then
    echo "Initializing Nix environment for root user"
    mkdir -p /root/.nix-profile /root/.nix-defexpr /root/.nix-channels
    ln -s /nix/var/nix/profiles/per-user/root/profile /root/.nix-profile
    ln -s /nix/var/nix/profiles/per-user/root/channels /root/.nix-defexpr
    ln -s /nix/var/nix/profiles/per-user/root/channels /root/.nix-channels
fi

if [[ -n "$NIX_MULTI_USER" ]]; then
    echo "Using Nix in multi-user mode"
    export NIX_REMOTE=daemon
    sudo nix-daemon > /tmp/nix-daemon.log 2>&1 & disown
fi

if [[ -n "$1" ]]; then
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