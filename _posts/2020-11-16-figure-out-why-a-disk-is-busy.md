---
layout: post
title: Figure out why a disk is busy
author: umhau
description: "Find the processes preventing a disk dismount"
tags: 
- linux
- lsof
- umount
- processes
categories: memos
---

Wish I'd known about this little gem years ago. When you can't get a disk to unmount, because it's 'busy', and you can't figure out what could possibly be occupying its attention, try this:

```
lsof +D /dev/diskpartition
```

The `lsof` command 'LiSts Open Files'. When used with the `+D` argument (weird format, I know), `lsof` will "search for all open instances of directory D and all the files and directories it contains to its complete depth."  There's also `+d`, which doesn't do a recursive search, but I don't think that would work when it's some subfolder of the mounted folder that's preventing the `umount` from happening.

Note, this command can take a while to finish. I did it twice, once when I needed it and once as a test; the first time, it found an old tmux session where I'd `cd`'d into the disk -- after searching for about 20 seconds. The second time, when I recreated the same situation, it returned the offending process almost immediately.  So age does matter - the older the process holding things up, the longer the search will take.
