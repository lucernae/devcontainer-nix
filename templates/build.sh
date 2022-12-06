#!/usr/bin/env bash

srcDir="$(pwd)/src"
testDir="$(pwd)/test"
ghActionDir="$(pwd)/../.github/actions/smoke-test"

templateID="$1"
testID="$2"

cd $PROJECT_DIR
bash $ghActionDir/build.sh $templateID $testDir/$testID
