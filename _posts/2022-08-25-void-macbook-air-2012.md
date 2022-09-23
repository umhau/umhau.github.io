---
layout: post
title: Notes Regarding the Installation of Linux on a mid-2012 Macbook Air
author: umhau
description: "Bugs and shortcomings"
tags: 
- Void Linux
- Macbook Air 2012
categories: memos
---

Bought a macbook air recently. It's an old one, but the hardware's cheap and with a decent linux install you don't really notice (except when you're using firefox). 

- FreeBSD couldn't handle the wifi card. I had to compile the kernel with special GPL code, enable specific kernel modules, and even then it only worked randomly. And we all know that random success is far worse than failure.  

So back to the loving arms of Void.

- When booting, hold the option/alt key down until the boot menu shows up. This lets you pick a USB boot device. 

The installation went smoothly - since there's no ethernet port, you'll have to either install the full graphical desktop environment, or learn to enable the wifi via the command line. It's not too hard. But it can be intellectually scary. Create the file below.

### cli wifi

```shell
# /etc/wpa_supplicant.conf
ctrl_interface=/run/wpa_supplicant
ctrl_interface_group=wheel
update_config=1

network={
    ssid="name of wifi network"
    psk="wifi password"
}
```

Then figure out what your wifi interface is. Run this:

```shell
find /sys/class/net -mindepth 1 -maxdepth 1 -lname '*virtual*' -prune -o -printf '%f\n' |
while read iface ; do
    echo interface: $iface
done
```

That will output all the network interfaces on your computer. If you're using a macbook air 2012, and you don't have a usb ethernet port plugged in, there will be just one output. It'll probably look like this:

```shell
wlp2s0b1
```

Then run the following command to connect to your wifi network. Notice the wif interface. Make sure it matches.  Ping google when you're done, to see if it all worked.

```shell
wpa_supplicant -B -i wlp2s0b1 -c /etc/wpa_supplicant.conf
```

I installed the i3 window manager. Needed a bunch of extra packages.  But that's all easy, and contained in the install script. The problem I had was with the touchpad - the cursor would only move vertically, and only if I swiped side-to-side. Hunted for an hour; finally found the solution. Turns out the kernel was loading the hardware in the wrong order. [This is the bug;](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1586552) looks like they just figured ignoring it would make it go away.  

All you gotta do is reload the kernel modules and we're golden. I wrapped it up in a script and run it on boot from `/etc/rc.local`. 

```shell
modprobe -r usbmouse
modprobe -r bcm5974
modprobe bcm5974
```

Also, if you want to modify the behavior of the mouse, this link should help: https://blog.inagaki.in/en/post/macbook-air-linux-3/

After that it's easy sailing. The keyboard is correctly mapped, so if you have a half-decent i3 config file a lot of things should "just work". 