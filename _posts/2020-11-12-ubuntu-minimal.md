---
layout: post
title: minimal ubuntu
author: umhau
description: "don't forget it's there"
tags: 
- ubuntu
- netboot
- tiny
- not even server edition
- 2GB disk usage
categories: memos
---

Personal note, to remember the existence of Ubuntu Mini.  I usually think of Ubuntu Server as being the minimal installation, but Mini includes Server Edition as one of the _extra_ package collections to add during installation. It's a netboot, which means that the .iso you download is just enough ubuntu to then download the rest from 'the cloud'. 

[http://cdimages.ubuntu.com/netboot/](http://cdimages.ubuntu.com/netboot/)

This netboot image, at least the 18.04 edition, is 64MB. Once installed, the disk usage is 2.0GB. By comparison, a fresh installation of Ubuntu Server 18.04 is 3.6GB, and the install disk is 173MB (the corresponding 20.04 disk is 945MB...not sure what happened there).  Only thing I added in each case is the SSH server.

I'd hoped the final installation would clock in at a fraction of a GB, but oh-well.  I'm thinking of checking out Alpine Linux next to crack that barrier.