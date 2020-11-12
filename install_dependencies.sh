#!/bin/bash

#                 do this on ubuntu - debian isn't up-to-date on Ruby (at least)

set -e                                    # if anything gives an error then exit

set -v                                        # echo every line before executing

sudo apt update                                           # on general principle

sudo apt install -y nodejs npm ruby ruby-dev ruby-full        # apt dependencies

sudo gem install jekyll bundler kramdown-parser-gfm           # gem dependencies

npm install simple-jekyll-search                              # npm dependencies

sudo script/bootstrap                                      # builds dependencies

bundle install                                           # install gemfiles, etc

echo "run the site with\'bundle exec jekyll serve\'"    # start the site locally