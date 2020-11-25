---
layout: post
title: A pixie server
author: umhau
description: "who doesn't like pixies?"
tags: 
- PXE
- TFTP
- DHCP
- NFS
- HTTP
- alphabet soup in a can
- linux
categories: walkthroughs
---

Confession. Every time I see the acronym 'PXE' I say it in my head as "pixie". It's not that far-fetched, I'm just inserting vowels to make it pronouncable. Like what you do when you're reading old Hebrew, I think.

I did this once before, years ago. It was horrible. It worked! But at what a cost. It was ugly, it took days to figure out, it required manual input at inconvenient times, and the tools that eventually worked were not the tools I wanted - only thing I could get to boot was an ubuntu server installation system, and I wanted OpenBSD.

Part of the problem was that I was scared of complexity. I didn't try and customize the gPXE image (to be fair, the tool I was pointed to has been offline now for what, almost a decade?) and running an HTTP server to host the boot files just seemed overwhelming. All that to say, setting up a network boot is a decently gigantic undertaking unless you're expert enough to know superior alternatives.

Another note: I'm not interested in serving installation disks. If I'm network booting, it's because I don't want to touch the recipient machines. So the end result here is going to be serving system files, with auto-altered configs where needed to ensure a modicum of uniqueness.

## outline

The steps involved in a network boot are complicated and non-intuitive. Much of this is legacy - PXE booting has to be able to deal with old machines with old network cards that have almost no memory and outdated (or even hardcoded) boot capabilities. 

Most of these steps are taken from the [Alpine Linux PXE boot howto](https://wiki.alpinelinux.org/wiki/PXE_boot). 

1. Set up a DHCP server and configure it to support PXE boot. 
2. Set up a TFTP server to serve the PXE bootloader.
3. Obtain / build the PXE bootloader.  
4. Set up an HTTP server to serve the rest of the boot files.
5. Set up an NFS server from which Alpine can load kernel modules.
6. Configure mkinitfs to generate a PXE-bootable initrd.


### set up a proxy-DHCP server

I don't want to mess with my preexisting DHCP server, and I want this PXE server to function successfully in a plug-and-play fashion -- just start it and go. Given that, we need to use something called a proxy-DHCP server. Instead of listening for and responding to all DHCP requests, it only responds to PXE-related requests. 

This is covered on page 18 of the [Preboot Execution Environment (PXE) Specification Version 2.1](https://raw.githubusercontent.com/umhau/umhau.github.io/master/data/pxespec.pdf). 

I found an interesting tool that could work fairly well. I hope that in the future I can do the PXE booting with IPV6, which would require adherence to a more recent UEFI 2.2 (or 2.6?) spec. The trouble is, IPV6 will only work after the iPXE bootloader is running on the booted system; to connect to the PXE server and download the iPXE bootloader, IPV4 is still required -- that's all that the old network cards can understand. So it won't be possible to completely escape IPV4. 

In which case, we might as well stick with a proxy-DHCP server that is a [clean and minimal implementation](https://github.com/gmoro/proxyDHCPd) of the complete PXE specification. (I'm not a fan of link rot, so there's a zip file of the whole github archive linked [here](after I make sure it's worthwhile).)

This kind of stuff doesn't change often, so don't be afraid of the fact it's been 10 years since the code was touched. It's not outdated; it's better than that -- it's complete.

```
sudo apt install python2
```

```
git clone https://github.com/gmoro/proxyDHCPd.git
cd proxyDHCPd
```



### build iPXE bootloader image

So the first thing to do is provide an improved piece of software with which to network boot: this is called iPXE. It used to be called gPXE, but that project died -- you can still find remnants on the web -- and iPXE is the new-and-improved fork.  

Download the source and build the image. I'm assuming you're on ubuntu or debian, but eventually I hope to script this process and run it on alpine.

Install dependencies.

```bash
sudo apt-get install gcc binutils make perl xz-utils mtools liblzma-dev  # also lzma-dev ?
```

Extras, needed only for building .iso images.

```bash
sudo apt-get install mkisofs syslinux 
```

Download iPXE code and cd into the source folder.

```bash
git clone git://git.ipxe.org/ipxe.git
cd ipxe/src
```

Normally, you can boot the iPXE image and use the command line it provides to connect to the network, download kernels, and generally do the stuff needed to boot something larger. Once you've figured out exactly what all those steps are, though, you can put them into a script and embed that script into the iPXE image.  (Note that by default, the script will exit if any command in it returns an error -- so be careful.)

```bash
#!ipxe

dhcp net0
chain http://${net0/next-server}/ipxe-script
```

Put that into a script called `script.ipxe`, and put the script into the `ipxe/src` folder. Then go ahead and build the image. This'll take a few minutes. 

Note that we're specifically trying to make a chainloading image that will be served with TFTP, with a custom embedded script. Without those constraints, we could just run `make` without the extra nonsense attached.

```
make bin/undionly.kpxe EMBED=script.ipx
```

And then grab the newly built image, and put it in the main ipxe folder for later use. 

```
cp -v bin/undionly.kpxe ../../ipxe.kpxe
```

Leave the ipxe directory. Done with building the iPXE image.

```
cd ../..
```

### set up proxy DHCP

Since we don't want to touch the DHCP server already on the network (the goal here is to make this PXE boot system as unobtrusive as possible), we have to set up what's called "proxy DHCP".  

I had a bad experience with dnsmasq last time, mostly because the complexity of that piece of software meant that my interactions with it were reduced to incantations. To me, it's a sign of too much complexity when you don't understand the commands you're using. 

So I looked for, and found, a piece of not-dnsmasq proxy DHCP software. Long as I don't need to worry about UEFI or IPV6, it'll work fine. IPV6 is for [later](https://blog.widodh.nl/2015/11/pxe-boot-over-ipv6-with-ipxe/). 

