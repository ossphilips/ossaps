## Introduction

**This file explains the ASP tool script.**

The APS tool (Assets Preprocessor Script) prepares assets from Kontich to be preprocessed for TACTIC and processing.
It expects a master excel file (containing information about luminaires)
and a zip file which contains corresponding colorsheet and view3d files

### Features

* Process all luminaires in the master excel file
* Extract colorsheets for each luminaire family and parse materials list
* Download reference images for each luminaire from images.philips.com
* Create summary files for each luminaire containing metadata (from master excel) and materials list (from colorsheet) 
* Check if luminaires are complete / incomplete and store all related files (summary, colorsheet, 3Dview, references images) in output folder
* Create CVS file with overview which luminaires are complete / incomplete
* Creates an error-log.txt in output folder
* Verbose logging (for debugging processing issues)


## Installation

A Gemfile is provided, so please run: `bundle`

### network configuration
The references images are downloaded from images.philips.com. This
server is only available within Philips using either a philips proxy server of by 
hardcoded the IP adres for this (akamai) server. This can be done 
by adding the following line to /etc/hosts (use for example 'su vi /etc/hosts')

23.62.99.120 images.philips.com

For your information:
images.philips.com is directly available outside the philips LAN 

## Tests

An RSpec test suite is available to ensure proper API functionality.
Please run `rspec` for testing the code.

A Guardfile is also provided, so please run `bundle exec guard`, for testing.


## Run the script

rake aps:process INPUT_DIR=/your/input_dir OUTPUT_DIR=/your/output_dir

## Debugging Issues

To debug processing issues (like invalid colorsheets) it is possible to
run the tool with verbose logging

export VERBOSE='true'
rake aps:process INPUT_DIR=/your/input_dir OUTPUT_DIR=/your/output_dir

