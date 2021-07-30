---
layout: post
title: Setting up OpenBSD (updated for 6.0)
date: '2016-11-09T11:19:00.000-05:00'
author: umhau
tags:
- ethernet
- OpenBSD
- OpenBSD 5.9
- package installation
- unix
categories: walkthroughs
---

A few notes on how I set up my OpenBSD installation.  This will be an ongoing compilation.

## Installation

Had to do this with a USB connected CD drive.  Followed the instructions for a flash drive, but the installation itself didn't want to play ball.  I forget the exact scenario; it was confusing.

### Wireless

I'm on an Acer Aspire One from a long time ago - I believe it's a D250 model.  It uses the athn0 wifi driver.  Set it up by putting this into your `/etc/hostname.ath0` file (copy the whole thing into the command prompt and run it):

```bash
echo "
nwid 'foo'
wpakey 'bar'
dhcp 
" > /etc/hostname.ath0
```

Replace the text as required with your own information...specifically, the stuff that says foo and bar.  :)  After that's added, run:

    sh /etc/netstart

...because it won't start automatically.  Don't know why.  I used this link to figure out how to get it running.

### Ethernet

If you have ethernet access, internet is somewhat simpler.  Find out what the ethernet device name is:

    ifconfig

Mine is fxp0.  Using DHCP makes things easy.  All this command does is put dhcp in the device's config file.

    echo dhcp > /etc/hostname.fxp0

Reboot, and you should be online.  Any problems, visit http://www.openbsd.org/faq/faq6.html#Setup and http://www.openbsd.org/faq/faq6.html#DHCP.

## Package Installation

See http://www.openbsd.org/faq/faq15.html#Intro for an excellent explanation of how all this works.

### Setting up the Package Mirror

Being able to install packages is always nice.  On OpenBSD, you have to specify the mirror you want to search from and download from manually.  You can set this variable after startup every time, or put it in your .profile.  I used the MIT mirror; it's not going anywhere anytime soon. [edit: ok, it did go.  They didn't keep the 5.9 mirror once 6.0 came out; here's the link to the 6.0 packages.]

    vi ./.profile

Now add (I stuck it in the middle of the file):

    export PKG_PATH=http://mirrors.mit.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/

Except that in my case this didn't work.  OpenBSD read that as

    mirrors.mit.edu/pub/OpenBSD/OpenBSD/packages/i386/

which doesn't make sense.  Instead, I had to do

    export PKG_PATH=http://mirrors.mit.edu/pub/OpenBSD/6.0/packages/$(uname -m)/

which destroys flexibility when I upgrade to 6.0 (whenever that comes out). Changed for compatibility with 6.0.

### Installing a Package

Now I can do

    pkg_add python-2.7.11

to install python 2.7 - but to get that full package name, I have to do CTRL-F in the mirror webpage and figure out what's available.  I'm pretty sure there's a way to search that on the command line, but I haven't figured it out yet.  If only the package name, and not the exact version number, is known, then just use that.  The following successfully installs nano.

    pkg_add nano

This can be simplified by an alias; e.g., `alias i='pkg_add '` and `alias r='pkg_delete '`.

## Turning the Computer Off

### Restarting

Restarting is simple: 

    reboot

### Shutting Down

You'd think this would be simple, eh?  Linux works with a straightforward

    shutdown now

but that eventually brings you right back to the shell on my computer's OpenBSD installation.  I have to use 

    halt

Though, and I haven't tried this yet, something like

    shutdown -h now

is also supposed to work.  This thread has more details.

