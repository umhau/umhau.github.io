---
layout: post
title: Expanding a RAID array with an additional disk
author: umhau
description: "using mdadm"
tags: 
- RAID
- mdadm
- linux
categories: walkthroughs
---

Question. Given a RAID array built with `mdadm`, is it possible to add another disk to it and expand its storage? 

Answer. Yes, but it's annoying. You have to prep the disk, add it, and then expand the filesystem.  And you have to do it all by hand. 

I tried making a script to do this automatically, but I'm pretty sure I'd never actually trust that script not to screw up - with the amount of sanity checking I was putting into it, it's better to just put the whole process here and do it manually.

So here goes. 

## Before we start

This works with a variety of RAID levels - and if your raid array is currently missing a disk, follow this walkthrough to prep the drive and add it as a hot spare, and the computer will take care of the rest.

If you ever want to see what's up with all your RAID arrays, use this command: 

```bash
cat /proc/mdstat
```

- You'll need local access to a drive not associated with the RAID array. This is for a small backup file, which (far as I can tell) keeps a second record of how the disks are arranged and how the data is broken up; if the raid alterations fail, this backup file is used to recover everything.
- Make sure you know what the name of the RAID device is that you're adding to. This will look something like `/dev/md3`, but likely with a different number at the end.
- Figure out how many disks are currently in the RAID array, you'll need that number later. Below is a quick script that can help. Save it as `count_raid_disks.sh`.

```sh
#!/bin/bash
# usage: bash count_raid_disks.sh 'md3'

[ -z "$1" ] && echo "provide the RAID device, e.g. 'md3'" && exit

wordcount=$(cat /proc/mdstat | grep $1 | wc -w)
echo "number of disks in RAID array $1: $(($wordcount-4))"
```

- Same goes for the disk you're adding.  It'll be something like `/dev/sdj`, but with a different letter at the end.
- Also, do some sanity checks. The last thing you want is to realize the drive was already in use somewhere. 

```sh
# say what your disk is. don't include a partition number ('sdj0') or '/dev/'
new_disk='sdj'

# check that the new disk is not mounted conventionally
mount | grep -q /dev/$new_disk && echo "new disk is already in use" && exit

# check that the new disk is not part of a RAID device
cat /proc/mdstat | grep $new_disk > /dev/null && echo "disk is part of a RAID device" && exit
```

## Prep the new disk

If the disk is clean and ready to roll, then go ahead and wipe it. 

Remember, adding the disk to RAID **will wipe everything**.  

This is your final warning. 

If you ignore it, run any of the following commands, and then run crying back because you lost some data, then this is my best advice: you shouldn't be a sysadmin. Maybe you should stick to Windows. And there's a chance -- just a chance -- that computers are just not your thing.

```sh
# specify the disk.
new_disk='sdj'

# zero out the first 1 GB of the drive; effectively clears all partition tables
sudo dd if=/dev/zero of=/dev/$new_disk bs=1M count=1000 status=progress

# make sure that none of the previous disk write is being held in buffer
sudo sync

# create new partition label
sudo parted /dev/$new_disk mklabel gpt & sync

# create new primary partition
sudo parted -a optimal /dev/$new_disk mkpart primary 0% 100% & sync

# turn on raid on the new addition
sudo parted /dev/$new_disk set 1 raid on & sync

# verify the formatting
parted /dev/$new_disk print
```

The disk is ready to be added to the array! 

## add the disk to the RAID array as a spare

First we add the disk as a hot spare. If we wanted, we could stop at that point and we'd have a RAID array of the same size, but with extra redundancy - if a drive were to fail, the hot spare would be automatically used as a replacement. Then the failed drive could be removed later. 

Hot spares aren't strictly necessary, because there's already redundancy built into the array - RAID 5 can lose 1 disk without data loss, RAID 6 can lose 2 disks. If a disk is lost, the RAID array will need a new disk to be added quickly; this hot spare means the RAID array can immediately begin moving data onto a replacement, instead of waiting around in the high-risk state with less room for disk failure. 

```sh
# specify the disk
new_disk='sdj'

# specify the raid device
raid_device='md3'

# add the disk as a hot spare
sudo mdadm /dev/$raid_device --add /dev/$new_disk
```

When the OS containing the RAID array turns on, the RAID array is just a bunch of disks attached to the computer. If they're supposed to be automatically turned into a single RAID array when the machine starts, you need to say so. 

In case you haven't yet noticed, we're using a tool called `mdadm` to work with this RAID array. In fact, these are considered 'mdadm RAID arrays'. That's because there's a lot of leeway in how each RAID variation can be implemented: size of the data chunks, how the records are kept of which piece is where, how the chunks are checked for errors, etc. Some of that (sometimes a lot of that, or even all of that) is up to the programmer who builds their version of RAID. It's not expected (so far as I know) that one dude's implementation of RAID be compatible with someone else's version; it appears that the standard definitions of the RAID levels just focus on the high-level stuff like 'number of drives that can fail without data loss'. 

All that to say, we need to edit an `mdadm` config file and tell `mdadm` that we want the RAID array assembled on startup.  There's going to be an entry already for the raid device we're working on, since what we're doing is a modification of an existing raid array. Comment out that entry with a `#`; we're going to add a new entry in a moment that will reflect the additional disk we just added. 

```sh
sudo nano /etc/mdadm/mdadm.conf
```

Then we want to add a new entry, for the updated RAID array.

```sh
# identify the raid device
raid_device='md3'

# append current raid configuration
sudo mdadm --detail --brief /dev/$raid_device | sudo tee -a /etc/mdadm/mdadm.conf
```

We now have a hot spare! If that's all we wanted, then we're done: if we were to shutdown and restart the host server, the RAID array would automatically reassemble. If one of the disks were to `fail` on us right now, the array would automatically detect that, and start moving data over onto the hot spare we just added. (Because that's the rub: the array is only designed for so many extras, so there's no way to know what data can be put onto the hot spare until something breaks...and when it does, it's going to take hours, or even days, to collect the needed data from the remaining drives in the RAID array and copy it over to the automatically-added hot spare [which isn't spare any more].)

Now, before you keep going, there's a point here worth mentioning. If you're trying to add multiple disks to the array, you can do that simultaneously - you don't need to add them individually, and wait hours/days for the array to grow over each one-by-one. If you have another disk to add, go back and do what we just did, again, with the other disk. Come back when you've added it to the RAID array just like the first.

When you're done with that, the RAID array should have _two_ hot spares attached. 

## grow the RAID array onto the spare

Now we tell the RAID array that it's bigger than it thought, and that it should expand itself onto the 'spare' that's now available.  We do this by getting the number of disks in the array; let's say there's 4 in there now.

```sh
bash count_raid_disks.sh 'md3'
```

Then, we tell the RAID array that hey, actually, there's (4 preexisting + 1 new hot spare) _5 disks_ in the array.  This is also where we need to know where we can put that backup file. 

By the way, if you're doing that thing where you add multiple hot spares at a time, then here you should tell the RAID array that you have e.g. (4 preexisting disks, and 2 hot spares = ) 6 disks in the array, instead of 5.

```sh
# identify the raid device
raid_device='md3'

# 4 preexisting disks + 1 new hot spare disk
new_disk_count=5

# place we can put a small (less than 10mb) backup file
raid_backup_filepath='/root/md3_grow.bak'

# tell the RAID array it has more disks than before
sudo mdadm --grow --raid-devices=5 --backup-file=$raid_backup_filepath /dev/$raid_device
```

This will take a long time. Possibly days. To view the progress, check the contents of this file:

```sh
cat /proc/mdstat
```

When this is done, check to see if there were any errors. This will require that the disk is unmounted, so do that first (if it's like mine, and used in passthrough mode by a virtual machine -- good luck! That's going to be a pain and a half to shut down, detach, and free up).

```sh
# don't do this until you're done!
umount /dev/md3
```

By the way, what kind of partition is on that drive? EXT3? EXT4? You'll need to figure that out if you want to run the right disk checker program. Mine is ext4, but yours might not be.  This might help:

```sh
# what partitions are associated with the raid array?
ls /dev/md3*

# if that command returned '/dev/md3p3', the following should give the
# partition type
df -T /dev/md3p3
```

You might have to detach from guest VMs, if that's relevant, before you get a proper partition read. Also, it only worked for me after I mounted the drive again on the host. So, uh, good luck.

Choose whichever of the following matches your EXT partition type. (If you're not using EXT_, I'm sorry for you and I have no suggestions. Perhaps a new career?)

```sh
fsck.ext4 -f /dev/md3
fsck.ext3 -f /dev/md3
```

Let it fix any issues, and move on to resizing the partition to expand to fill the available space.

```sh
resize2fs /dev/md3
```

At this point, you should be done!