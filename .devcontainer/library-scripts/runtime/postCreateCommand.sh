#!/usr/bin/env bash
# Add this at the top of the script
set -x
echo "Debugging postCreateCommand.sh"
pwd
ls -l /library-scripts/runtime
echo "Running postCreateCommand script..."

# Example: Update nix channels
if nix-channel --list | grep -q "nixpkgs"; then
    echo "Updating nixpkgs channel..."
    nix-channel --update
else
    echo "Adding and updating nixpkgs channel..."
    nix-channel --add https://nixos.org/channels/nixpkgs-23.05 nixpkgs
    nix-channel --update
fi
echo "PostCreateCommand script completed."
# run prebuild scripts based on configuration
bash /library-scripts/runtime/prebuild-default-package.sh
bash /library-scripts/runtime/prebuild-nix-shell.sh
bash /library-scripts/runtime/prebuild-flake.sh
bash /library-scripts/runtime/prebuild-flake-develop.sh
bash /library-scripts/runtime/prebuild-flake-run.sh
bash /library-scripts/runtime/prebuild-home-manager.sh
bash /library-scripts/runtime/prebuild-home-manager-flake.sh
bash /library-scripts/runtime/use-direnv.sh

exec "$@"