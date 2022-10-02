---
layout: post
title: nfs read-only file share
author: umhau
description: "quick note on making an NFS share"
tags: 
- NFS
- linux
- debian
- share drive
categories: walkthroughs
---

This is actually pretty easy. I'm doing this particular share for my media NAS, so that VLC on my phone can access it (only on android though, VLC can't access NFS shares on iPhones last I checked).  

Install dependencies.

```bash
apt-get install nfs-kernel-server nfs-common
```

Open the file that manages the shared NFS folders, and add a new line.

```bash
sudo nano /etc/exports
```

The new line should look like this:

```sh
/folder/to/share 192.168.1.1/24(ro,subtree_check,insecure,sync)
```

That's a decent configuration to allow anyone connected to the local network (e.g., on the same home wifi connection) to access - but not edit - the contents of the shared folder.  

Refresh the NFS shares, and then verify, and you're done.
```bash
exportfs -r
exportfs -v
```

