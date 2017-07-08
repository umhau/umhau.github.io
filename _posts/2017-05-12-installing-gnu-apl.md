---
layout: post
title: Installing GNU APL
date: '2017-05-12T20:51:00.001-04:00'
author: umhau
tags:
- Linux
- dyalog
- Ubuntu GNOME 17.04
- package installation
- APL
---

Three parts: the program itself, the keyboard layout and the font.  This is on Ubuntu GNOME 17.04.

Install GNU APL
---------------

    cd ~/Downloads
    wget ftp://ftp.gnu.org/gnu/apl/apl-1.7.tar.gz
    tar xzf apl-1.7.tar.gz
    cd apl-1.7
    ./configure
    make 
    sudo make install

Set up the keyboard  
-------------------

This is to provide access to the varied and very weird set of characters APL uses. Ubuntu GNOME, as of 17.04, doesn't like to play with APL any more.  So this flies under the radar a bit.  

Prevent Gnome Shell from reverting changes:

    gsettings set org.gnome.desktop.input-sources sources '[]'

Enable the new keyboard layout:

    setxkbmap us,apl -option "grp:switch"

APL385 Unicode
--------------

Set a good fixed-width font so the symbols show up correctly.  Go here: https://www.dyalog.com/apl-font-keyboard.htm, download the recommended font, open and install it.  Then use the GNOME Tweak Tool to set the font as the default in the terminal:

    fonts -> monospace -> APL385 Unicode Regular -> Select

And you're done.