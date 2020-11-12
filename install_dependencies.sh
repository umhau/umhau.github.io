#!/bin/bash

set -e 
set -v

sudo apt update

[ `which curl 2>/dev/null` ] || sudo apt install curl

if [ ! `which nodejs 2>/dev/null` ]
then
    curl -sL https://deb.nodesource.com/setup_15.x | sudo -E bash -
    sudo apt-get install build-essential nodejs
fi 

# sudo apt install nodejs npm


# install ruby
# sudo apt install -y ruby ruby-dev ruby-full
# gpg --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
# curl -sSL https://get.rvm.io | bash -s stable
# curl -sSL https://get.rvm.io | bash -s stable --rails

# sudo apt install openssl zlib1g libreadline7 libreadline-dev libgdbm-dev
# if [ ! `which ruby 2>/dev/null` ]
# then
#     wget https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.6.tar.gz
#     tar -xzf ruby-2.6.6.tar.gz
#     cd ruby-2.6.6
#     ./configure
#     make
#     sudo make install 
#     cd ..
# fi

wget -O ruby-install-0.7.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.7.1.tar.gz
tar -xzvf ruby-install-0.7.1.tar.gz
cd ruby-install-0.7.1/
sudo make install

sudo gem install jekyll bundler
sudo gem install kramdown-parser-gfm

npm install simple-jekyll-search

script/bootstrap # builds dependencies
bundle install # install gemfiles, etc

