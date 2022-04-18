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

Here's something fun. I ran into a problem where I needed to move a linux installation (old 32 bit ubuntu with some specialized drivers installed -- long story) out of a virtual machine to a physical box - and then, a few months later, back into a different virtual machine in a different hypervisor.  Fun times; and a tough proposition when big usb drives aren't really available. 

The alternative, of course, is to 'just' push the disk image over the network. Without a cache. Directly from /dev/original to /dev/youfailed.  The kind of thing where you double-check your incantations and then pray mightily to every deity in the list you compiled last time things went south.

Thankfully someone invented pipes, which means this is relatively easy to string together.  Replace the contents of the variable 'targetip' with the ip address of the computer that's _receiving_ the disk image.  

The `count` variable specifies the size of the disk you're moving in megabytes - the boot sector + single, primary partition of this unfortunate computer is slightly less than 35GB, so I'm rounding up and making sure the drives at each end are bigger than that. Empty space after the partition is fine. This command is being run from the machine where the computer currently resides, and is _sending_ the data to the new computer.

```shell
targetip=192.168.1.33
dd if=/dev/sda bs=1M count=35000 | gzip | ssh root@$targetip "gunzip | sudo dd of=/dev/xvda"
```

I left out any kind of status indicator. Not sure how well that would play with the piping that's going on.  Also, remember to replace the disks with the ones you're working with. If you don't know what I mean by that, then don't come anywhere near this post.
