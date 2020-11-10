---
layout: post
title: find stuff fast (ish)
author: umhau
description: "easy (ish) to remember, and very effective"
tags: 
- command line
- find
- grep
- linux
- not windows
- good luck on iOS
categories: memos
---

I ran into this command combo once, when I was digging through the `~/.bash_history` of a FreePBX Asterisk server I'd inherited that was glitching out (long story...). It stuck with me, not because it was elegant (it's not), but because it's so obvious, and so easy to remember.

I don't remember what the previous dude was looking for, but it was a situation where there's a file _somewhere_ on the system, buried in any number of layers of `/opt/usr/local/bin/local/tryagain/` system folders.

```
find / . | grep "search term"
```
That's it. You have `find` spit out the path of every file on the system in succession, and then check each one for a match. 

However, be careful: this will enumerate everything that the system can see. That might include some distant, high-latency, freeze-your-system-while-you-wait NFS mounts. If you can, replace the `/` with a more targeted initial search directory.
