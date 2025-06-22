#!/usr/bin/env bash

# Reset default ACL on /tmp. This is crucial because the default ACLs
# might prevent Nix from setting the correct umask during build processes,
# leading to permission errors.
sudo setfacl -k /tmp

# Initialize Nix environment for the root user if it doesn't exist.
# This ensures that root has the necessary profiles and channels set up,
# which might be needed for certain operations or if running commands as root.
if [[ ! -d /root/.nix-profile ]]; then
    echo "Initializing Nix environment for root user"
    mkdir -p /root/.nix-profile /root/.nix-defexpr /root/.nix-channels
    ln -s /nix/var/nix/profiles/per-user/root/profile /root/.nix-profile
    ln -s /nix/var/nix/profiles/per-user/root/channels /root/.nix-defexpr
    ln -s /nix/var/nix/profiles/per-user/root/channels /root/.nix-channels
fi

# If NIX_MULTI_USER is set, start the nix-daemon in the background.
# This enables multi-user Nix operations.
if [[ -n "$NIX_MULTI_USER" ]]; then
    echo "Using Nix in multi-user mode"
    export NIX_REMOTE=daemon
    sudo nix-daemon > /tmp/nix-daemon.log 2>&1 & disown
fi

# Change to the target directory if provided as the first argument.
if [[ -n "$1" ]]; then
    echo "Target directory: $1"
    cd $1
fi

# If a .envrc file exists, allow it and execute the subsequent command within its environment.
# This integrates direnv functionality into the container's entrypoint.
if [[ -f .envrc ]]; then
    echo "Activating direnv"
    . ~/.nix-profile/etc/profile.d/nix.sh
    direnv allow ./.envrc
    direnv exec . "${@:2}"
fi

# Execute the command passed after the optional directory argument.
exec "${@:2}"