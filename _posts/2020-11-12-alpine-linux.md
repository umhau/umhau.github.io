---
layout: post
title: the extreme tininess of Alpine Linux
author: umhau
description: "it's really small!"
tags: 
- Alpine
- standard installation
- tiny
- linux
categories: memos
---

Test no. 2 in the quest for a tiny linux distro. This time I'm checking out [alpine linux](https://www.alpinelinux.org/downloads/) (it's the distro used inside docker files).  

The [installation process](https://wiki.alpinelinux.org/wiki/Installation#3._Boot_and_install_process) is very bare-bones; it reminded me of openbsd and void linux. 

The disk image, optimized for virtual systems, weighs in at 39MB. After installation (ssh server included, just like the ubuntu variants), running 

```
du -h -d 0 /
``` 

to get the disk space used gives me a total of 98.8MB. Crazy, right? 

## ssh access

By the way: logging in as root over ssh with a password doesn't work. I was even on the freenode IRC channel, and those fine folks couldn't get it working. If you want to ssh in as root (an admittedly bad idea, but for scripted remote root file management there isn't a better alternative), [you'll have to use a key](https://umhau.github.io/set-up-passwordless-ssh/). 

Alternately, just create a new user after installation and use the new account for ssh access. 

```
adduser myself
```

Once logged in, you can easily switch to the root account.

```
su
```

That command, in general, switches you to the specified account. If no argument is given, it assumes you want the `root` account.

## turning it off

The shutdown command isn't used on Alpine. Instead, use:

```
poweroff
```

## install man pages

Turns out, it doesn't come with man pages installed. Install them:

```
apk add mandoc man-pages
```