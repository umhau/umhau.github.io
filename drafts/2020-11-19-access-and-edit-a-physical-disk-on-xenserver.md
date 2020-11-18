---
layout: post
title: access and edit a virtual disk on xenserver / xcp-ng
author: umhau
description: "good for pulling old data or setting up a new VM"
tags: 
- xenserver
- xcp-ng
- virtual disk
- mount
- linux
- VHD
- XVA
categories: experiments
---

It looks like the virtual disks on a xen server are some weird hybrid of files and mounted devices. The upshot is, there's no actual file path that points to an actual file that can be copied somewhere else (I imagine there's some performance enhancements involved). I.e., if you pull the drive from a xen server installation and mount it on another OS, there's no virtual disk file to be found. I don't understand it either, but that seems to be the state of affairs. Who knows _where_ the data actually is.

In order to manipulate a virtual disk, an 'actual' file has to be created. This can be done at least two ways: via the creation of a snapshot, or by directly exporting it. I'm not sure what the pros and cons are yet, which is why this post is labeled under 'experiments' rather than 'walkthroughs'.

Note: this post doesn't actually have a solution. It's a record of some research I did, which eventually pointed me in a different direction altogether. Negative results only, though I might find some of the pieces useful in the future.

### exporting

Exporting a disk into the custom XVA disk image format is relatively easy, though it does require custom tools and results in a format one coder has called a "[strangely crafted tar-file](https://github.com/eriklax/xva-img)". This means, if you're one this page because you nuked your xenserver / xcp-ng installation and are trying to recover info from a disk - good luck, this probably won't work.

```
xe vm-export vm=<name-of-vm-get-it-from-the-console> filename=<output_file.xva>
```

This XVA file is basically a complete physical disk, which means it's not going to be easy to pull anything off of it.  There is a [tool](https://github.com/eriklax/xva-img) I found, written in C++, that could do the trick.  As of November 2020, it's only compatible with xcp-ng 8.0, not 8.1 or above. Something about a new hash scheme (it looks like the new one is a speed improvement) that hasn't been implemented. If this avenue is sufficiently important, I might have to figure out enough C++ to make a patch.

The other downside is that these conversions take a while, and even after all the above rigmarole the virtual disk will still have to be wrapped back up and imported into the hypervisor. If this is happening frequently and on a tight schedule, it's not the way to go.

### templates and snapshots, oh my!

If the template / snapshot route is going to work, I still need to be able to get inside the VM and change files around, and be able to identify the IP address of the new VM.  

There could be a two-part solution here. The IP address problem could be solved either with the DHCP server, managing and interacting with that, or using the built-in xcp-ng function to enter the VM console. With the console option, I'm not sure if that can be scripted since the context switch could mess with how a bash script is executed, similarly to the problems involved with using a script to run commands via ssh on a remote machine. Trying to pull an IP address out of the console could be very messy. On the other hand, interacting with the DHCP server will probably be necessary anyway; though it will likely be just as complicated.

Given that the IP address is obtained, the rest of the modifications could be performed through ssh.  I just have to make sure that the template I start with will allow root logins, and is configured to use the hypervisor's admin ssh key.  Once that's set up, it's a matter of generating a new key, adding it in, changing the root password, and removing the old key. That can be done with one-liners over ssh and scp uploads.

#### getting the IP address

This will likely be a whole different post, eventually. However, it looks like I overlooked one option: since the MAC address of the VM is defined externally in the hypervisor, I can get that easily - and I can scan the network to find the IP address associated with it.  This is a quick & dirty solution, and it should be replaced, but it can work for now.

```bash 
#!/bin/bash
# DO NOT KEEP THIS AS A SCRIPT! JUST HOLD ONTO IT AND TEST BEFORE GIVING ONE-LINERS
# Find the ip address for xen guest without login the machine.
# it needs nmap and some standard linux tools
# install nmap e.g apt-get install nmap
# USAGE: ./xen-guest-ip 10.100.207.0 24
# set -x
network=$1
subnet=$2
printf “Enter guest ID: “
read ID

# Use xenstore to find the mac associated with VM
mac=`xenstore-read /local/domain/$ID/device/vif/0/mac`
umac=`echo $mac | tr “[:lower:]” “[:upper:]”`

# Search the local networking for all up machines and find the IP address.
ip=`nmap -sP $network/$subnet |  grep -B 2 $umac | grep Host | awk ‘{print $2}’`
echo “IP address for Guest ID $ID is \”$ip\””
```


#### edit the VM through SSH

Once the IP address is known, we can move on to the modifications of the VM.


### sources

https://serverfault.com/questions/723919/xenserver-vhd-data-recovery

https://www.computerweekly.com/tip/How-to-mount-Xen-virtual-machine-storage-on-physical-hosts

https://serverfault.com/a/314428

export and mount: https://github.com/eriklax/xva-img