---
layout: post
title: Alpine Linux package building
author: umhau
description: "Hard to figure out "
tags: 
- Alpine Linux
- apk
- build
categories: memos
---

It's been a real pain to figure out how to mess with packages in Alpine Linux.

Here's a quick overview of how to edit a preexisting package. 

```
sudo apk add alpine-sdk
git clone git://git.alpinelinux.org/aports 
cd aports
```

Enter the subdirectory of the package you want to mess with.

```
cd community/<pkg name>
```

Now there's a file called APKBUILD in that directory. That file is a complete description of how to build and install a package.  To build the package as-is, run

```
abuild -r
```

If you make and adjustments -- e.g., change the version number -- you'll have to run

```
abuild checksum
```

and then do `abuild -r` again.

Be sure you have enough space for the compilation process to happen.

Source: [https://wiki.alpinelinux.org/wiki/Creating_an_Alpine_package](https://wiki.alpinelinux.org/wiki/Creating_an_Alpine_package#Use_a_template_APKBUILD)