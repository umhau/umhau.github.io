Ever feel like giving your xen virtual machine direct access to a local disk? Ever try doing that?

```sh
vim /etc/udev/rules.d/59-udev.rules
```

Inside that file, add two lines:

```sh
ACTION=="add", RUN+="/bin/sh -c 'mkdir -p  /dev/xapi/block/'"
```

This line is just prep, so to speak.

```sh
ACTION=="add", RUN+="/bin/sh -c 'ln -s /dev/sdb /dev/xapi/block/'"
```

Where `sdb` is the disk you want to add. You can add as many disks as you want, just add more of this line to the file.

It really is that easy.