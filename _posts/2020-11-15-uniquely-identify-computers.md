---
layout: post
title: unique hardware IDs
author: umhau
description: "keep track of your stuff"
tags: 
- uniqueness is underrated
- also overrated
- linux
- sysadmin
- PXE
categories: memos
---


There's a lot of supposedly unique serial numbers and hardware IDs scattered over computer hardware these days. I ran into a project where it would be really nice to track computers that a particular program has already seen. 

You might be thinking "licensing". You'd be wrong, surprisingly. I'm looking at setting up zero clients, with hostname persistence across reboots in the local network: given a unique ID, the PXE host can maintain a list of unique IDs, so that freshly booted systems can check for whether they've already seen the hardware, and if so what their hostname should be.  It's not an adversarial environment, so there's no need to worry about fake IDs; however, I can't guarantee that network cards or hard drives will remain constant -- in fact, I'm pretty sure they won't. 

What will remain constant, or at least, what will come and go with the machines themselves, is the motherboard. (I could also set up a relationship graph and work out which clusters of HW IDs tend to stay together, just in case someone, somewhere, replaces their motherboard - but that's a bit too involved for my tastes.)

So, here's how to pull the hardware IDs for various components.

**motherboard** requires a recent linux kernel. A virtual machine will present a faux ID to the guest OS.

```bash
cat /sys/class/dmi/id/board_serial
```

**MAC address** easily changed in software, but the original number remains constant.

```bash
ifconfig -a | awk '/^[a-z]/ { iface=$1; mac=$NF; next } /inet addr:/ { print iface, mac }'
```

**Hard drive serial number** will change every time you swap disks.  Don't forget to specify which device you want: `/dev/sdX`.

```bash
udevadm info --query=all --name=/dev/sdX | grep ID_SERIAL
```

Apparently, only Pentium III CPUs have accessible serial numbers, so getting CPU IDs is out.
