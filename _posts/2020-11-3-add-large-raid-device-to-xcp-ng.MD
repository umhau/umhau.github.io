---
layout: post
title: add large raid device to xcp-ng
author: umhau
description: "when you need a lot of storage on the hypervisor"
tags: 
- xcp-ng
- xen
- RAID
- block devices
categories: walkthroughs
---

(Relevant to xcp-ng 7.0)

There's three different ways that a RAID device can be used on a xen or xcp-ng
hypervisor: obviously, a RAID device can be mounted directly on the centos 
substrate, and used via scripts running outside the management consoles; it can 
be added as a 'storage repository', which is somewhere that VMs can be placed; 
or it can be attached directly to one of the VMs.  

There are some strange limitations around the size of large drives, that it may
be well to be aware of.  I don't remember what they are, unfortunately, but they
deal with drives around or larger than two terabytes.

In any case, the first thing to do is clean the drives and create the new RAID 
device. If there's a preexisting RAID device using any of the drives involved,
the partition management commands will not work and it'll probably tell you to
reboot the computer. This is not necessary, will not work, and does not solve
the underlying issue.  Just remove the old RAID device.

```
bash remove_raid_device.sh -m md0 -d "c e b d"
bash raid-autoconf.sh -r 5 -m md0 -e ext4 -d "c e b d" -c 4
```

### mount directly on the centos hypervisor

Mounting is pretty simple. This WILL NOT make the drives accessible through the
management consoles (xen orchestra or XCP-ng Center), or through any of the VMs
on the hypervisor.

```
mkdir /mnt/RAID
mount /dev/md0 /mnt/RAID
```

### attach as a storage repository 

If you want the storage space of the RAID device to be available for putting 
virtual machines on, then the RAID device should be made into a storage 
repository.  This is the type of storage that can be managed within the 
management consoles built for xen server. 

```
xe sr-create \
    name-label=<Storage ID> \
    shared=false \
    device-config:device=<Path of the Storage device> \
    type=lvm \
    content-type=user
```

The storage ID is the name you want to assign to the storage repository - for 
example, 'raid_storage_1'.  The path of the storage device is something like 
```
/dev/md0
```
to use the example above.  After running that command, the storage 
should be available in the management console.

NOTE that setting up the storage like this will PREVENT it from being accessed 
from within a virtual machine. It will only be able to be used to HOLD virtual
machines.

### attach directly to a virtual machine

This, finally, is the third use of a large drive.  Generally, you can just 
attach USBs with passthrough to a virtual machine. This is sometimes convenient
when you want to, for instance, back up the contents of a VM to a drive you can 
easily physically remove from the server in case of problems.

However, (and I think this is where the storage size limitations come into play)
it's not possible to 'passthrough' very large drives to a VM this way. Something 
to do with xen server still using the EXT3 filesystem, which has a max file size
of about 2TB? Could be remembering wrong, I did the research on that a few 
months ago.

After creating the RAID device (above), we create a rule to pass the array 
through to the VM as a block device. 

Open the file with the related rules (which seems to manage what xen server does
with attached block devices):

```
nano /etc/udev/rules.d/65-md-incremental.rules
```

And then, just before the end of the file, add this line:

```
KERNEL=="md0", SUBSYSTEM=="block", ACTION=="change", \
    SYMLINK+="xapi/block/%k", \
    RUN+="/bin/sh -c '/opt/xensource/libexec/local-device-change %k 2>&1 >/dev/null&'"
```

Note that the first argument is "md0": this should be changed to the device 
you're using; it's consistent with the previous examples where we're using 
/dev/md0.  That's the only thing that needs to be changed.

The only line that follows the one you added should be this one:

```
LABEL="md_end"
```

This rule will automatically make the /dev/md0 block device available to be 
attached to any VM on the hypervisor host.  Open the management console and 
attach the device.  Then you can mount it from within the VM.