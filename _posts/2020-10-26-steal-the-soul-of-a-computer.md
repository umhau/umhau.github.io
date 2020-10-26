---
layout: post
title: Steal the Soul of a Computer
author: umhau
description: "The in-place imaging and transfer of a computer"
tags: 
- dd
- linux
- ssh
- pain in the butt
categories: walkthroughs
---

Here's something fun. Ever wanted to completely screw up your computer? Well, wait no longer. I ran into a problem where I needed to move a linux installation (old 32 bit ubuntu with some specialized drivers installed -- long story) out of a virtual machine to a physical box - and then, a few months later, back into a different virtual machine in a different hypervisor.  Fun times; and a tough proposition when big usb drives aren't really available. 

The alternative, of course, is to 'just' push the disk image over the network. Without a cache. Directly from /dev/original to /dev/copy.  The kind of thing where you double-check your incantations and then pray to every deity in the list you compiled the last time around, when something inside systemd broke on your irreplaceable production machine.

Thankfully someone invented pipes, which means this is relatively easy to string together.  Replace the contents of the variable `targetip' with the ip address of the computer that's _receiving_ the disk image.

```shell
targetip=192.168.1.33
dd if=/dev/sda bs=1M count=35000 | gzip | ssh root@$targetip "gunzip | sudo dd of=/dev/xvda"
```

Also remember to replace the disks with the ones you're working with. If you don't know what I mean by that, then don't come anywhere near this post.
