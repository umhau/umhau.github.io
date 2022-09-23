---
layout: post
title: Set up Xen on Alpine Linux
author: umhau
description: "Just the beginning"
tags: 
- Xen
- Dom0
- Alpine
- Linux
categories: walkthroughs
---

So I'm starting out on this new project. The first iteration is just VMs on a box - but they're Xen VMs, and they're on an Alpine box.  Later iterations shall be revealed, all in good time. Much work has been done behind the scenes, and much work is yet to be done.

Anyway, Xen vms on Alpine. Start with a clean alpine installation, then enable the community repository.

First become root. You should remain root for the duration of this walkthrough.

```Shell
su
```

```Shell
cat /etc/os-release

repository_server="dl-cdn.alpinelinux.org"
alpine_version="v3.16"

echo "https://$repository_server/alpine/$alpine_version/main" > /etc/apk/repositories
```

Install the hypervisor, and related packages.

```Shell
apk add xen xen-hypervisor seabios xen-qemu # ovmf
apk add grub grub-bios
```

Load the necessary kernel modules.

```Shell
echo "xen-netback" >> /etc/modules
echo "xen-blkback" >> /etc/modules
echo "tun" >> /etc/modules
```

And add the xen daemons.

```Shell
rc-update add xenconsoled
rc-update add xendomains
rc-update add xenqemu
rc-update add xenstored
```

Then reboot; because kernel mods don't immediately take effect, and those daemons haven't autostarted yet.

```Shell
reboot
```

Now we get to do the tricky stuff: GRUB modifications. If you recall your Xen, you'll remember that it's got a special Dom0 that manages the other VMs on the host. We need to specify some configs for that VM, and the place to do that is in GRUB, before things like "RAM size" are determined.

Add the following to the bottom of the grub config. Note that you may want to increase the size of the dom0 RAM; just change `1024M` to some larger number.

```Shell
vim /etc/default/grub

# You need to set the amount of RAM to allocate to the Dom0 Alpine install so that
# our future virtual machines will have enough memory.
GRUB_CMDLINE_XEN_DEFAULT="dom0_mem=1024M,max:1024M"

GRUB_DEFAULT="saved"
GRUB_SAVEDEFAULT="true"
```

Then apply the new config.

```Shell
grub-mkconfig -o /boot/grub/grub.cfg
grub-set-default "$(grep ^menuentry /boot/grub/grub.cfg | grep Xen | cut -d \' -f 2 | head -1)"
```

> That sets the default entry in GRUB to the first entry containing 'Xen'. **Run this every time you upgrade Alpine or Xen.**

One last thing. Do you plan to use more than 8 VMs? Probably. If so, be sure to increase the maximum number of loop devices. 

> In Alpine Linux, you will need to add the max_loop option to the loop module, then add the loop module to your initramfs. 

```Shell
touch /etc/modprobe.d/loop.conf
echo "options loop max_loop=32" > /etc/modprobe.d/loop.conf
```

Then update the modules list and reboot.

```Shell
mkinitfs
reboot
```