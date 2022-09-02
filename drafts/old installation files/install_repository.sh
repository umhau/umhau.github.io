#!/bin/bash

# assuming that the repository is in the home directory and named as below.

REPO_NAME=myrepository

tar -xvf ~/$REPO_NAME.tar; mv ~/$REPO_NAME /usr/local/
echo "deb [trusted=yes] file:/usr/local/$REPO_NAME ./" | sudo tee -a /etc/apt/sources.list
sudo apt-get update

