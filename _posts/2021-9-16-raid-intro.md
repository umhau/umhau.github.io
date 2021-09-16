---
layout: post
title: RAID Intro
author: umhau
description: "quick overview of RAID"
tags: 
- RAID
categories: walkthroughs
---

## RAID

No, not the military action. RAID drives are a Redundant Array of Inexpensive Disks, great for when you need more storage in one place than a single drive can provide. It's a way to use software (or hardware) to glue together a bunch of disks into something that looks to a computer like one big disk.

There's a bunch of different ways to do the gluing, and they each have pros and cons. If you're really worried about losing some valuable data, you can get 2 or more identical disks and put the data on all of them. Then you lose one disk and you haven't lost any data. That's "RAID 2".  Or, if you take a more cowboy approach, you can do a "RAID 0", where you just sum the drives together without any redundancy...lose one though, and you lose everything. 

The rest of the RAID variations are compromises between these two approaches. The table below describes exactly what the tradeoffs of each RAID level are.

Space, fault tolerance, and performance shown as ratios of single drive 
performance.  Thus, in a 4-drive RAID6 configuration: `1-2/[4] = 1-1/2 = 1/2`,
which means the available space is `1/2` the total capacity of the 4 drives.

```
RAID      Minimum   Space      Fault      Read      Write performance
level     drives    efficiency tolerance  perf.

RAID 0    2         1          None       n         n
RAID 1    2         1/n        n − 1      n [a]     1 [c]
RAID 4    3         1 − 1/n    1 [b]      n − 1     n − 1 [e]
RAID 5    3         1 − 1/n    1          n [e]     1/4 [e]
RAID 6    4         1 − 2/n    2          n [e]     1/6 [e]

[a]  Theoretical maximum, as low as single-disk performance in practice.
[b]  Just don't lose the pairity disk.
[c]  If disks with different speeds are used in a RAID 1 array, overall write 
     performance is equal to the speed of the slowest disk. 
[e]  That is the worst-case scenario, when the minimum possible data (a single
     logical sector) needs to be written. Best-case scenario, given 
     sufficiently capable hardware and a full sector of data to write: n − 1.
     This is because data is written in predetermined 'chunk' sizes; if the 
     data is much smaller than the chunk, the whole chunk must still be 
     written.
```

**RAID 0** is just an aggregation of all the disks, with no fault tolerance. If one
of the drives dies, the whole thing is toast. 

**RAID 1** consists of an exact copy (or mirror) of a set of data on two or more 
disks. The array can only be as big as the smallest member disk. This layout 
is useful when read performance or reliability is more important than write 
performance or the resulting data storage capacity. The array will continue 
to operate so long as at least one member drive is operational.

Random read performance of a RAID 1 array may equal up to the sum of each 
member's performance, while the write performance remains at the level of a 
single disk. However, if disks with different speeds are used in a RAID 1 
array, overall write performance is equal to the speed of the slowest disk.

**RAID 5** consists of block-level striping with distributed parity. Parity 
information is distributed among the drives. It requires that all drives but 
one be present to operate. Upon failure of a single drive, subsequent reads can
be calculated from the distributed parity such that no data is lost. RAID 5 
requires at least three disks.

**RAID 6** is any form of RAID that can continue to execute read and write requests
to all of a RAID array's virtual disks in the presence of any two concurrent 
disk failures. RAID 6 does not have a performance penalty for read operations, 
but it does have a performance penalty on write operations because of the 
overhead associated with parity calculations. RAID 6 can read up to the same 
speed as RAID 5 with the same number of physical drives.
