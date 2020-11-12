#!/bin/bash

set -e 
set -v

sudo apt update

# [ `which curl 2>/dev/null` ] || sudo apt install curl

# if [ ! `which nodejs 2>/dev/null` ]
# then
#     curl -sL https://deb.nodesource.com/setup_15.x | sudo -E bash -
#     sudo apt-get install build-essential nodejs
# fi 

sudo apt install nodejs npm
# install ruby
sudo apt install -y ruby ruby-dev ruby-full

# sudo snap install ruby

sudo gem install jekyll bundler
sudo gem install kramdown-parser-gfm

npm install simple-jekyll-search

script/bootstrap # builds dependencies
bundle install # install gemfiles, etc

