---
layout: post
title: force time synchronization on windows
author: umhau
description: "time management"
tags: 
- windows server
- powershell
- NTP
- time synchonization
- sysadmin
categories: memos
---

One of my clients has a windows server, that's used as the time server for the local network. For some reason, the server itself stopped synchronizing with any external time servers. 

So all the windows machines on the network slowly drifted out of sync with the rest of the world. Of course, they were all in sync with each other, which led me to realize the source of the issue. 

Do this in powershell. First make sure the machine has a list of time servers to synchronize from.

```
w32tm /config /update /manualpeerlist:"0.pool.ntp.org,0x8 1.pool.ntp.org,0x8 2.pool.ntp.org,0x8 3.pool.ntp.org,0x8" /syncfromflags:MANUAL
```

Then force windows to actually synchronize.

```
w32tm /resync /force
```

That forced the server to resync its clocks, which in turn resynchronized the clocks on all the local windows machines. It doesn't solve the underlying issue, and I don't know why the server stopped synchronizing; but that can be solved after the immediate problem is addressed. If you have even a modicum of discipline to follow through on the proper fix, that attitude won't lead to tech debt.

[Source](https://superuser.com/a/1363801).