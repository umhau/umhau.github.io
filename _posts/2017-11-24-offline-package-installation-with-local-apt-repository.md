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

There's a lot of difficulties associated with installing packages to an offline computer, especially when the packages are complicated. (Banshee is _horrible_.)  So, after several errors and many trials, it looks like I should create a local apt repository.  I have about 20 packages I want to install, and that list is not getting shorter.  The following is my attempt to simplify the process as much as possible.  [src](https://askubuntu.com/questions/170348/how-to-create-a-local-apt-repository#176546).

do this on the online computer
------------------------------

### Download package files with dependencies

There's a process involved with downloading and saving packages and dependencies. The following collects the packages into a single folder in the user home directory.  **Make sure the computer downloading these packages has the same OS version (e.g. Ubuntu Server 16.04) and CPU processor (i386 vs AMD64) as the computer that the packages will be installed on.** I usually set up a virtual machine to match the processor and OS of the offline computer. The trouble is getting files off that VM and onto your flash drive.

Run the following lines, one at a time, in the terminal.

    pkgs=(banshee vlc emacs )
    fnm="/home/`whoami`/myrepository && mkdir $fnm
    for PKG in "${pkgs[@]}"; do sudo apt -d install $PKG -y; sudo cp -n /var/cache/apt/archives/*.deb "$fnm/"; sudo apt clean; done

### Create the apt index file

You'll need an extra bit of software before you can build the package index apt needs to read. 

    sudo apt-get install dpkg-dev
    cd /home/`whoami`/myrepository
    dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
    sudo update-mydebs

Great! You have a local apt repository. After you tell apt about it, you can install software from it like you're online.  Time to move it onto the offline computer - and that's way easier said than done. The process is easier if the repository is in an uncompressed .tar archive. Compression isn't relevant here, since those .deb files are already compressed. 

    cd; tar cfv "$fnm".tar $fnm

Alright, that can take a while. When it's done, get the .tar file onto a flash drive, and move it to the main user directory of the offline computer.  Virtualbox can let you insert a flash drive, but if you have another computer that you can ssh into, scp is a tool for using a similar protocol to move files between computers. 

    scp $fnm user@othercomputer:/path/to/home/directory

on the offline computer
-----------------------

You need to tell apt about the new repository!  Otherwise it won't have any idea what you just did. Soooooo, run this line in the terminal of the offline computer after you put the software collection somewhere safe.  One nice place is in /usr/local.  If you already copied the .tar file to the home directory of the offline computer, the following will extract it, move it, and tell apt about it.

    tar -xvf ~/myrepository.tar
    mv ~/myrepository /usr/local/
    echo "deb [trusted=yes] file:/usr/local/myrepository ./" | sudo tee -a /etc/apt/sources.list
    sudo apt-get update

All done!  Now you can install the packages you downloades like you're online.  

    sudo apt-get install banshee vlc emacs

The big advantage of this process over using dpkg is when there's lots of complicated dependencies - you can't make the .deb files install in order with dpkg, but you can with apt.
