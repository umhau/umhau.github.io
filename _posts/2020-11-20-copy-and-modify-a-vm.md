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

### set up the initial virtual machine

The initial setup of the virtual machine should be done by hand. It'll be done very rarely, and only when you need to make specific changes -- you'll hopefully make the changes once, ever, and duplicate the VM from then on.

Create a new VM, using the 'other install media' template, and [install Alpine Linux](https://umhau.github.io/alpine-linux/) on it.  You'll have to [upload](https://umhau.github.io/create-local-ISO-repository-on-xcp-ng/) the correct disk to the hypervisor's ISO storage repository.

![](https://raw.githubusercontent.com/umhau/umhau.github.io/master/images/other-install-media.JPG)

Since it's a general-purpose template, there's no default disk included. You'll have to add one. I'm going with 1GB.

![](https://raw.githubusercontent.com/umhau/umhau.github.io/master/images/add-virtual-disk.jpg)

Start it & [install Alpine](https://umhau.github.io/alpine-linux/).  

Once Alpine is installed, set up [passwordless ssh](https://umhau.github.io/set-up-passwordless-ssh/).  

At this point, the VM can be accessed remotely, and is a fairly clean slate. It's ready for on-demand duplication.

### making copies

Now we go through the steps that should be scripted, and run sequentially every time you need a copy of the VM.

Identify the UUID of the virtual machine you created:

```
xe vm-list
```

And create a new copy of the VM. 

```
xe vm-copy new-name-label=<new name for the new VM> vm=<name or UUID of the copied VM>
```

Now we have a fresh, clean VM. In case you want some details about that last command, I'll quote them to you. 

> vm-copy
> reqd params : new-name-label
> optional params : new-name-description, sr-uuid, <vm-selectors>
> description : Copy an existing VM, but without using storage-level fast disk clone operation (even if this is available). The disk images of the copied VM are guaranteed to be 'full images' - i.e. not part of a CoW chain. The simplest way to select the VM on which the operation is to be performed is by supplying the argument 'vm=<name or uuid>'. VMs can also be specified by filtering the full list of VMs on the values of fields. For example, specifying 'power-state=halted' will select all VMs whose power-state field is equal to 'halted'. Where multiple VMs are matching, the option '--multiple' must be specified to perform the operation. The full list of fields that can be matched can be obtained by the command 'xe vm-list params=all'. If no parameters to select VMs are given, the operation will be performed on all VMs. 

### customizing the duplicated VM

Now. Opening up the virtual hard drive associated with the VM is a no-go; I tried, and couldn't figure it out. It looks like the virtual disks on a xen server are some weird hybrid of files and mounted devices. The upshot is, there's no actual file path that points to an actual file that can be copied somewhere else (I imagine there's some performance enhancements involved).

As a result: to edit the contents of the VM with a script, judicious use of `ssh` and `scp` will be required. The former can execute arbitrary commands inside the VM (remember how you put a root ssh key in the template VM?), and the latter can upload config files, scripts and tarballs into the VM. That's how we're going to do the customization.

First, we need the IP address of the VM. To find that, we need the MAC address: the MAC address is a hardware configuration, which we can obtain through xen. Once we have that, we can search the assigned IP addresses for the one associated with that MAC address.

