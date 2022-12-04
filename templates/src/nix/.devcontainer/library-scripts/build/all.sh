#!/usr/bin/env bash

# run prebuild scripts based on configuration
bash /library-scripts/build/additional-nix-channel.sh
bash /library-scripts/build/use-flake.sh
bash /library-scripts/build/additional-nix-flake-registry.sh
bash /library-scripts/build/install-root-packages.sh
bash /library-scripts/build/prebuild-home-manager.sh
bash /library-scripts/build/use-direnv.sh
