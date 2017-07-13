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

GNU APL
-------

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

Clear any prior settings:

    setxkbmap -option ""

And enable the new keyboard layout:

    setxkbmap us,apl -option "grp:switch"

Now the APL keyboard characters can be accessed while pressing down the Right Alt key.  You can view the APL keyboard layout (if you're using Ubuntu GNOME 17.04) with this command:

    gkbd-keyboard-display -l apl

I wrapped all of this into a couple of scripts. One of them runs at startup (since setxkbmap isn't persistent across reboots), and the other displays the keyboard layout and is tied to a custom shortcut. The scripts are [here](https://github.com/umhau/scripts/blob/master/installation/keyboard_layout.sh) and [here] (https://github.com/umhau/scripts/blob/master/apl_keyboard_hint.sh).  Those link to the github where I stash most of my scripts.  If you look inside the initial_config.sh script, you'll see I've found a command to automatically set the script to run at startup.  For the other, I'd suggest the keyboard shotcut combination [win + .]. 

APL385 Unicode
--------------

Set a good fixed-width font so the symbols show up correctly.  Go here: https://www.dyalog.com/apl-font-keyboard.htm, download the recommended font, open and install it.  Then use the GNOME Tweak Tool to set the font as the default in the terminal:

    fonts -> monospace -> APL385 Unicode Regular -> Select

And you're done.

Sources
-------

- https://stackoverflow.com/questions/27951582/apl-keymapping-on-linux-gnu-apl
- https://unix.stackexchange.com/a/45499
- https://unix.stackexchange.com/a/317057
