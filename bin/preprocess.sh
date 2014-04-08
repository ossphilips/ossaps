#!/bin/bash

cd $OSSACT_FOLDER/scripts/aps
bundle install
bundle exec rake aps:process INPUT_DIR=$1 OUTPUT_DIR=$2

exit $?
