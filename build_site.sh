#!/bin/bash

set -e 
set -v

# set up new blog using minimal theme (built & customized locally)
# run this after installing dependencies

sudo script/bootstrap # builds dependencies
bundle install # install gemfiles, etc

bundle exec jekyll serve # and you can access the site at http://localhost:4000/
