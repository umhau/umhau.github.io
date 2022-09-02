---
layout: post
title: Windows in a qemu VM with functional audio I/O
author: umhau
description: "dual-booting is boring"
tags: 
- qemu
- Windows
- VM
- audio
categories: walkthroughs
---

Run windows 10 as a virtual machine guest, without internet. source: https://wiki.gentoo.org/wiki/QEMU/Windows_guest

Download Windows 10 here: https://www.microsoft.com/en-us/software-download/windows10ISO

Download driver file here: https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md

    wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

create virtual hdd
    qemu-img create -f qcow2 WindowsVM.img 25G

```Bash
#!/bin/sh
exec qemu-system-x86_64 -enable-kvm \
        -cpu host \
        -drive file=WindowsVM.img,if=virtio \
        -net nic -net user,hostname=windowsvm \
        -m 1G \
        -monitor stdio \
        -name "Windows" \
        "$@"
```


perform installation
    ./WindowsVM.sh -boot d -drive file=WINDOWS.iso,media=cdrom -drive file=DRIVER.iso,media=cdrom
