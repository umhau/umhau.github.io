---
layout: post
title: Offline package installation with local apt repository
author: umhau
description: "sometimes there's just too many packages"
tags: 
- Ubuntu 17.10 
- apt 
- package management
- offline computer systems
- terminal
categories: walkthroughs
---

how to set up a local apt repository
====================================

There's a lot of difficulties associated with installing packages to an offline computer, especially when the packages are complicated. (Banshee is _horrible_.)  So, after several errors and many trials, it looks like I should create a local apt repository.  I have about 20 packages I want to install, and that list is not getting shorter.  The following is my attempt to simplify the process as much as possible.  [src](https://askubuntu.com/questions/170348/how-to-create-a-local-apt-repository#176546).

do this on the online computer
------------------------------

### Download package files with dependencies

There's a process involved with downloading and saving packages and dependencies. The following collects the packages into a single folder in the user home directory.  **Make sure the computer downloading these packages has the same OS version (e.g. Ubuntu Server 16.04) and CPU processor (i386 vs AMD64) as the computer that the packages will be installed on.**

Run the following lines, one at a time, in the terminal.

    p=(banshee vlc syncthing sublime-text )
    fnm="/home/`whoami`/offline-apt-package-archive && mkdir $fnm
    for PKG in "${pkgs[@]}"; do sudo apt -d install $PKG -y; sudo cp -n /var/cache/apt/archives/*.deb "$fnm/"; sudo apt clean; done

### Create the apt index file

You'll need an extra bit of software before you can build the package index apt needs to read. 

    sudo apt-get install dpkg-dev
    cd /home/`whoami`/offline-apt-package-archive
    dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
    sudo update-mydebs

Great! You have a local apt repository.  After you tell apt about it, you can install software from it like you're online.  

Now, if you feel like it (or have a smaller flash drive), you can compress the directory.

    cd # get out of the package archive directory 
    tar czfv "$fnm".tar.gz $fnm

Time to put that .tar.gz file on a flash drive and move it to the main user directory of the offline computer.

on the offline computer
-----------------------

You need to tell apt about the new repository!  Otherwise it won't have any idea what you just did. Soooooo, run this line in the terminal of the offline computer after you put the software collection somewhere safe.  One nice place is in /usr/local.  If you already copied the compressed file to the home directory of the offline computer, the following will extract it, move it, and tell apt about it.

    tar -xvzf ~/offline-apt-package-archive.tar.gz
    mv ~/offline-apt-package-archive /usr/local/
    echo "deb file:/usr/local/mydebs ./" | sudo tee -a /etc/apt/sources.list
    sudo apt-get update

All done!  Now you can install the packages like you're online.  

    sudo apt-get install banshee syncthing vlc sublime-text

The big advantage of this process over using dpkg is when there's lots of complicated dependencies - you can't make the .deb files install in order with dpkg, but you can with apt.