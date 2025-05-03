#!/usr/bin/env bash

# run prebuild scripts based on configuration using the correct path
bash /tmp/library-scripts/build/additional-nix-channel.sh
bash /tmp/library-scripts/build/use-flake.sh
bash /tmp/library-scripts/build/additional-nix-flake-registry.sh
bash /tmp/library-scripts/build/install-root-packages.sh
bash /tmp/library-scripts/build/prebuild-home-manager.sh
bash /tmp/library-scripts/build/use-direnv.sh
