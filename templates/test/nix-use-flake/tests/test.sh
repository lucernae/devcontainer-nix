#!/bin/bash
cd $(dirname "$0")/../
source test-project/test-utils.sh

# Template specific tests
check "direnv status" direnv status
check "root packages installed" curl --version
check "check nix build" nix build
check "check nix develop" nix develop --check
check "check nix run" nix run
check "direnv executed" nix develop --command bash -c 'if [ "$MY_HOOK" == "true" ]; then echo "$MY_HOOK"; else exit 1; fi'

# Report result
reportResults
