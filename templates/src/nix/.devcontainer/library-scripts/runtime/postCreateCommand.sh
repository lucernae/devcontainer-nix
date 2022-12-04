#!/usr/bin/env bash

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