---
layout: post
title: samba file share
author: umhau
description: "make a local cloud that talks nice with windows"
tags: 
- samba
- nfs
- network
- debian
- windows
categories: walkthroughs
---

I've done this before, but it's super annoying and I keep forgetting how. So here it is, stashed where I won't forget. I've tried NFS before, the opensource-originating variation of network file storage, but the defaults were really bad.  If I mounted an NFS share and the wifi was unreliable, my file browser - or even my whole computer - would freeze.  Not good.  I tried, but never discovered, an incantation that would render NFS a desirable tool.  So if you're wondering why I'm not using it, that's the reason. Try sshfs instead. At least when it fails, it fails in a non-destructive manner.

I'm going to use Samba.  This is for my media collection, which I usually access either on the windows laptop or through VLC on my android phone. In both cases, SMB works far better than NFS. Note that there is a vast number of configurations that are possible; this setup is intended for sharing a folder to myself on a local network that isn't compromised, and where I don't mind anyone on the network accessing and modifying the files.

```
su
apt-get install samba smbclient samba-common
```

Choose a folder to share. It's simpler, sometimes, to create a new folder somewhere out-of-the-way, that you can toss shared files into.  You could even share a mounted external drive this way.  

```
su
mkdir -pv  /network/sambashare
chmod -R 0775 /network/sambashare
chown -R nobody:nobody /network/sambashare
```

Backup the samba configuration file before editing.  Always a nice practice.

```
cp -v /etc/samba/smb.conf /etc/samba/smb.conf.bak
su 
nano /etc/samba/smb.conf
```

Inside smb.conf, put this new entry at the end of the file:

```
[shared_folder] 
  path = /network/sambashare 
  writable = yes 
  guest ok = yes 
  guest only = yes 
  create mode = 0777 
  directory mode = 0777
```

