#!/bin/bash
cd $(dirname "$0")/../
source test-project/test-utils.sh

# Template specific tests
check "htop is installed" command -v htop
check "session env var was set" zsh -c 'if [[ "$MY_VAR" == "Foo" ]]; then echo "$MY_VAR"; else exit 1; fi'

# Report result
reportResults
