#!/bin/bash
cd $(dirname "$0")/../
source test-project/test-utils.sh

# Template specific tests
check "direnv status" direnv status
check "root packages installed" curl --version
check "default package installed" nix-shell --run hello
check "direnv executed" nix-shell --run  'if [ "$MY_HOOK" == "true" ]; then echo "$MY_HOOK"; else exit 1; fi'

# Report result
reportResults
