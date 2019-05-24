#!/usr/bin/env bash

# use set -e instead of #!/bin/bash -e in case we're
# called with `bash ~/bin/scriptname`
set -e # bail out early if any command fails
set -u # fail if we hit unset variables
set -o pipefail # fail if any component of any pipe fails

./change_weight.sh demo app-green 100
./change_weight.sh demo app-blue 1
