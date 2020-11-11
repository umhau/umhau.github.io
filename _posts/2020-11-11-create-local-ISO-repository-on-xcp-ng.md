---
layout: post
title: Create local ISO repository on xcp-ng / xenserver
author: umhau
description: "short-term satisfaction"
tags: 
- xcp-ng
- xen
- not the best way, but the easiest
- linux
categories: walkthroughs
---

The most annoying part of xcp-ng is that there's no way to upload an installation disk image to the hypervisor to actually set up the first virtual machine. Far as I can tell, one is expected to set up a separate iSCI host to hold all the various disk images and ISOs needed. What I'll do later is an NFS share with the ISOs on it, but that's after I set up some sort of minimal management server running some tiny OS off a battery backup with out-of-band seconary access.  Seems like that's the ideal setup to reliably bootstrap a hypervisor in a (presumed) unreliable, remote environment.

For now, however, I'm putting superfluous ISO storage repositories on each server I set up (I can't share the "SR" between the servers, because one is running xcp-ng 8.0 and the other is 8.2). 

Log into the hypervisor through ssh.

```
ssh root@<hypervisor hostname or IP>
```

Decide where to put the ISO storage repository. I think `/var/opt/xen/` is a default location, but it really doesn't matter. Stick it in `/root/`, jam it in `/opt/diskimages/`, I don't care. Though, `/tmp/` wouldn't be a good choice, and `/dev/` or `/proc/` would probably kill your system.  Note the trailing `/`, which will be important later on when this variable is reused.

```
sr_path="/var/opt/xen/instalation_disks/"
mkdir -pv $sr_path
```

Pick a name for your ISO repository. This is what will show up in XCP-ng Center as the name of the storage repository, so pick something at least semi-memorable. 

```
sr_name="installation disk images"

This is where the magic happens: tell the hypervisor about the purpose of the new folder, and specify that it's specifically for the purpose of holding ISOs that get inserted in virtual DVD drives.

```
xe sr-create name-label="$sr_name" type=iso device-config:location="$sr_path" \
    device-config:legacy_mode=true content-type=iso
```

Now you can open up XCP-ng Center and see the new ISO repository. It'll be empty, though, so the next trick is adding the disks. I like using the debian net installer as a default OS, so the Debian 10 netinstall ISO will be my example here. 

For some reason, `wget` doesn't like running inside the hypervisor in my experience; maybe it'll be different for you. If you feel like experimenting, try this: 

```
cd $sr_path
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.6.0-amd64-netinst.iso
```

However, I've usually found it effective to download it to a different (linux) system, and then upload it with `scp` to the hypervisor. (again, all this nonsense will be superceded when I set up that management box with an NFS ISO repository...)  Do the following on the not-hypervisor linux system. 

``` 
hypervisor_ip_address="192.168.1.XXX"
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.6.0-amd64-netinst.iso
scp debian-10.6.0-amd64-netinst.iso root@"$hypervisor_ip_address":"$sr_path"
```

Note that I'm continuing to use the same bash variables defined earlier for the repository path.  At this point, you can go back into XCP-ng Center and refresh the contents of your storage repository and see the new disk image. If you do, it's ready for use setting up a new VM. If you don't...it worked for me. 

