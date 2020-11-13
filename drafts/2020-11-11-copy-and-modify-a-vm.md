---
layout: copy and modify a virtual machine
author: umhau
description: "automate the deployment of virtual machines"
tags: 
- xcp-ng
- linux
- automation
- hypervisor
- ssh
categories: walkthroughs
---

I'm trying to find a programmatic way to start and stop hundreds of tiny virtual machines.  In order to start up a new virtual machine, there's a few things that have to be customized. 

- the MAC address should be altered - randomized, probably, or maybe sequential if you're feeling snazzy.
- hostname should be changed to something unique.
- an ssh key should be generated.
- the root password should be changed.

You might be tempted to try and copy the virtual disk, mount it, make the edits, and then start the new VM with all-fresh settings -- I was. However, it turns out that the virtual disk is very hard to access; for one thing, there isn't (apparently) even an image on-disk that can be mounted: it has to be exported, then [converted](https://github.com/eriklax/xva-img), then mounted, then re-converted, then imported. Not gonna happen.

Instead, we'll take a different route. I'm going to manually set up the first VM, then snapshot it and create a template from the snapshot. Then each subsequent VM will be created using the snapshot; I'll then change the MAC address, and after it's turned on, ssh in and perform the needed changes.  Should be a piece of cake.

I'll assume you can find your way more-or-less around XCP-ng Center. 

## create the template virtual machine

Create a new VM, using the 'other install media' template, and [install Alpine Linux](https://umhau.github.io/alpine-linux/) on it.  You'll have to [upload](https://umhau.github.io/create-local-ISO-repository-on-xcp-ng/) the correct disk to the hypervisor's ISO storage repository.

![](https://raw.githubusercontent.com/umhau/umhau.github.io/master/images/other-install-media.JPG)

Since it's a general-purpose template, there's no default disk included. You'll have to add one. I'm going with 1GB.

![](https://raw.githubusercontent.com/umhau/umhau.github.io/master/images/add-virtual-disk.jpg)

Start it & install Alpine.

