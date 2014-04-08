#!/bin/bash

cd $OSSAPS_FOLDER
bundle install
bundle exec rake aps:process INPUT_DIR=$1 OUTPUT_DIR=$2
EXIT_CODE=$?
[ $EXIT_CODE -ne 0 ] && { echo "Usage: $0 <input_dir> <output_dir>"; }

exit $EXIT_CODE
