#!/bin/bash

cd $OSSAPS_FOLDER
bundle install
bundle exec rake aps:process INPUT_DIR=$1 OUTPUT_DIR=$2
EXIT_CODE=$?
[ $EXIT_CODE -ne 0 ] && { echo "Usage: $0 INPUT_DIR=<input_dir> OUTPUT_DIR=<output_dir>"; }

exit $EXIT_CODE
