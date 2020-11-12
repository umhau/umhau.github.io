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

The virtual installation disk, optimized for virtual systems, weighs in at 39MB. After installation (ssh server included, just like the ubuntu variants), running `du -h -d 0 /` to get the disk space used gives me a total of 98.8MB. Crazy, right? 

By the way: logging in with ssh as root isn't allowed by default. I haven't found the right setting to change yet, so after installation just add a new user (it'll prompt you for a new password) and login as them. 

```
adduser myself
```

To do things as root, just type
```
su
```
to change your user to `root`.