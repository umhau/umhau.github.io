---
layout: post
title: QEMU and Windows
author: umhau
description: "CLI management of QEMU virtual machines"
tags: 
- QEMU
- virtualization
- Linux
- Windows
categories: walkthroughs
---

This is a quick lesson in how to use [QEMU](https://www.qemu.org/) for all your Windows VM hosting needs. Personally, I just want want a linux box within easy reach of my Windows machine...this is a quick and dirty way to do that.   

I'm using batch files (`.bat`) and commands for what follows. They're what runs in `cmd.exe`, _not_ powershell (though that might work too...).

I'm also using powershell.

## Install QEMU

Go to the [QEMU site](https://www.qemu.org/download/#windows) and [download](https://qemu.weilnetz.de/w64/) the Windows installer, then run it. It's the `qemu-w64-setup-20210817.exe` file (as of writing) in case you're wondering.  The installation will put a bunch of files in the `C:\Program Files\qemu\` directory.

Once installed, add the QEMU installation location to the system path (this is temporary). (powershell only)

```Powershell
$env:Path += ";C:\Program Files\qemu"
```

## create the QEMU disk image

This is the 'hard drive' you're installing the OS on. First you have to make it, then you can use it. I'm putting this drive in a subfolder of `My Documents` called `virtual_machines`.

```Batch
cd Documents
mkdir virtual_machines
cd virtual_machines
dir
"C:\Program Files\qemu\qemu-img.exe" create void.musl.img 8G
```

## Install the OS

Download the OS installation disk - this can be the 'CD' or 'DVD' version instead of the USB version, since it'll be presented to the OS as an optical disk.  Beware! This is a very long command.  

I'm using Void Linux for the guest OS, so the file is downloaded from [here](https://alpha.de.repo.voidlinux.org/live/current/void-live-x86_64-musl-20210218.iso) (as of publication date - otherwise, go looking [here](https://voidlinux.org/download/) for the latest version).  The name of the downloaded file is `void-live-x86_64-musl-20210218.iso`. Put it in the same folder where the virtual disks are. 

Note the hardcoded values in the command below: 2G of RAM; the VM's name is `void_musl`; the name of the virtual disk file is `void.musl.img`. The values have been made consistent throughout this post, so copy-paste (shameful as that is) shouldn't break.

```Batch
start "QEMU" "C:\Program Files\qemu\qemu-system-x86_64.exe" -drive file=void.musl.img,index=0,media=disk,format=raw -cdrom void-live-x86_64-musl-20210218.iso -m 2G -L Bios -usbdevice mouse -usbdevice keyboard -boot menu=on -rtc base=localtime,clock=host -parallel none -serial none -name void_musl -no-acpi -no-hpet -no-reboot 
```

This will run the VM with a console (virtual monitor screen). To run it without that screen, use `qemu-system-x86_64w.exe` as the executable. (Note the `w`.)

## Run the VM

Once the VM has been set up, the day-to-day execution of the VM will use a slightly different command from that last one: specifically, the VM virtual HDD will be the boot disk, rather than the optical installation disk.

```Batch
start "QEMU" "C:\Program Files\qemu\qemu-system-x86_64w.exe" -drive file=void.musl.img,index=0,media=disk,format=raw -m 2G -L Bios -usbdevice mouse -usbdevice keyboard -boot menu=on -rtc base=localtime,clock=host -parallel none -serial none -name void_musl -no-acpi -no-hpet -no-reboot -device e1000,netdev=user.0 -netdev user,id=user.0,hostfwd=tcp::2222-:22
```

Note that the last set of configs in the command will allow ssh access to the VM: ssh into `username@localhost:2222`.

There's also an accelleration option. https://dev.to/whaleshark271/using-qemu-on-windows-10-home-edition-4062

When you're ready to streamline it, create a file named `void.bat` and put it in the same `virtual_machines` folder as everything else. Inside, put the following:

```Batch
start "QEMU" "C:\Program Files\qemu\qemu-system-x86_64w.exe" -drive file=void.musl.img,index=0,media=disk,format=raw -m 2G -L Bios -usbdevice mouse -usbdevice keyboard -boot menu=on -rtc base=localtime,clock=host -nographic -parallel none -serial none -name void_musl -no-acpi -no-hpet -no-reboot -device e1000,netdev=user.0 -netdev user,id=user.0,hostfwd=tcp::2222-:22
```

Save it, right click, and "ceate a shortcut". Then put the shortcut in your start menu, or on your desktop, or wherever. This will open the virtual machine without graphical output (a display), but after a minute or so, you'll be able to get in with ssh! Pretty cool stuff. 

Just don't open it twice. ;)

# other opinionated examples

## alpine linux

There's a special 'virtual' [version](https://alpinelinux.org/downloads/) of this OS, just for us. `<3` [Go get it.](https://dl-cdn.alpinelinux.org/alpine/v3.14/releases/x86_64/alpine-virt-3.14.2-x86_64.iso)

We don't need a lot of space here, so don't waste it. 1 GB should be enough.

```Batch
cd Documents
cd virtual_machines
"C:\Program Files\qemu\qemu-img.exe" create alpine.img 1G
```

We're also going easy on the RAM allocation: 128M instead of 2G.

```Batch
start "QEMU" "C:\Program Files\qemu\qemu-system-x86_64.exe" ^
-drive file=alpine.img,index=0,media=disk,format=raw ^
-cdrom alpine-virt-3.14.2-x86_64.iso -m 128 -L Bios ^
-usbdevice mouse -usbdevice keyboard -boot menu=on ^
-rtc base=localtime,clock=host -parallel none -serial none -name alpine ^
-no-acpi -no-hpet -no-reboot 
```

Alpine has a thing where by default, it won't let you ssh in as root with a mere password. Boot the newly installed OS once with graphics attached, then add another account that will let you ssh with a password.

```Batch
start "QEMU" "C:\Program Files\qemu\qemu-system-x86_64.exe" ^
-drive file=alpine.img,index=0,media=disk,format=raw -m 128 -L Bios ^
-usbdevice mouse -usbdevice keyboard -boot menu=on ^
-rtc base=localtime,clock=host -parallel none -serial none -name alpine ^
-no-acpi -no-hpet -no-reboot -device e1000,netdev=user.0 ^
-netdev user,id=user.0,hostfwd=tcp::2223-:22
```

    adduser bob
    poweroff

Once that's done, we don't need the graphic output anymore. Put the following into an `alpine.headless.bat` file, just as with the void linux example above.  After that, you can create a shortcut that gets shoved anywhere you like. 

```Batch
start "QEMU" "C:\Program Files\qemu\qemu-system-x86_64w.exe" ^
-drive file=alpine.img,index=0,media=disk,format=raw -m 128 -L Bios ^
-usbdevice mouse -usbdevice keyboard -boot menu=on -nographic ^
-rtc base=localtime,clock=host -parallel none -serial none -name alpine ^
-no-acpi -no-hpet -no-reboot -device e1000,netdev=user.0 ^
-netdev user,id=user.0,hostfwd=tcp::2223-:22
```

One trouble with the headless version is (big surprise...), there's no real indication (besides the the task manager) of whether it's running and if it's finished turning on yet. 

Note that the ssh port is 2223 for this one. 

It looks like QEMU uses nearly a gigabyte of RAM for its overhead. Kindof annoying, when I was hoping for a cheap, low-resource local VM.

## raspberry pi

For that sweet, sweet Mathematica access, yo

Grab the [raspbian image file](http://downloads.raspberrypi.org/raspbian/images/raspbian-2020-02-14/2020-02-13-raspbian-buster.zip). Put it in the `Documents\virtual_machines` folder.

It's a little more complicated, since the disk image has to be manipulated by hand...but it's still doable.

