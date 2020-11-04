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

I'm including the contents of these two scripts at the bottom of this post;
they're also in one of my repositories, but that might change and I might rename
or otherwise alter them.

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

### scripts

#### remove_raid_device.sh

```
#!/bin/bash

set -e
set -v

# usage: bash remove_raid_device.sh -m /dev/mdX -d "e v f m"

while getopts ":m:d:" opt; do
  case $opt in
    m) raid_device="$OPTARG"
    ;;
    d) drive_list="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG. " >&2
    ;;
  esac
done

[ -z $raid_device ] && echo "Specify RAID device." && cat /proc/mdstat && exit
[ -z $drive_list ] && echo "specify list of drives connected to RAID." && exit

devicelist=$(eval echo  /dev/sd{`echo "$drive_list" | tr ' ' ,`}1)

echo "Drives connected to RAID: $devicelist"
echo -n "Removing RAID device $raid_device. Confirm > "; read

if mount | grep $raid_device > /dev/null; then umount $1; fi

mdadm --stop "$raid_device"                             # deactivate RAID device

mdadm --remove "$raid_device" || true  # remove device - this may sometimes fail

mdadm --zero-superblock $devicelist  # remove superblocks from all related disks

rm -fv /etc/mdadm.conf        # delete file that identifies RAID devices on boot
```

#### raid-autoconf.sh

```
#!/bin/bash

set -e
set -v

# this script creates a new RAID device from scratch, given the drive letters 
# of the HDDs you want to use and the raid level. 

# it only works on centos, since it was written for use with xen server.

# raid level options: 0, 1, 5, 6 
# multidevice: the /dev/[xxx] name of the raid device comprising all the drives
# filesystem type: choose from ext2, ext3, or ext4
# drive list: JUST THE LETTERS of each /dev/sd[X] drive
# bash raid-autoconf.sh -r 5 -m md1 -e ext4 -d "a b d g"

# there is a confirmation sequence before anything is written.

# LIMITATION: this does not account for hot spares. NOTE that the 
# autoconf script will not account for leaving a drive unused as a hot swap. If 
# you want to do that, then you'll have to modify the script or just run the 
# commands manually. I'd have to rewrite the script with a ton more complexity to 
# account for that, and I'd rather just make a second, simpler script for that
# specific scenario.

while getopts ":r:d:m:e:c:" opt; do
  case $opt in
    r) raid_level="$OPTARG"
    ;;
    m) raid_multi_device="$OPTARG"
    ;;
    e) filesystemtype="$OPTARG"
    ;;
    d) drive_list="$OPTARG"
    ;;
    c) drive_count="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG. " >&2
    ;;
  esac
done

[ -z "$raid_level" ] && echo "raid level not specified." && exit
[ -z "$raid_multi_device" ] && echo "multidevice not specified." && exit
[ -z "$filesystemtype" ] && echo "filesystem type not specified." && exit
[ -z "$drive_list" ] && echo "drive list not specified." && exit
[ -z "$drive_count" ] && echo "number of drives not specified." && exit

printf "Using RAID %s\n" "$raid_level"
printf "Using /dev/sd[X] drive letters: %s\n" "$drive_list"
printf "Multidevice specified:  /dev/%s\n" "$raid_multi_device"
printf "Filesystem chosen: %s\n" "$filesystemtype"
printf "Number of drives to be formatted: %s\n" "$drive_count"

for drive in ${drive_list[@]}
do
    if mount | grep /dev/sd$drive > /dev/null
    then 
      echo "ERROR: /dev/sd$drive is mounted."
      exit
    elif cat /proc/mdstat | grep sd$drive > /dev/null
    then
      echo "ERROR: /dev/sd$drive is part of a preexisting RAID device. Remove"
      echo "that device before proceeding."
      echo "https://www.looklinux.com/how-to-remove-raid-in-linux/"
      exit
    fi
done


echo "confirm: using drives ${drive_list[@]} for new software RAID $raid_level array."
echo -ne "\t ALL DATA ON ALL LISTED DRIVES WILL BE LOST! > "; read

[ `which parted   2>/dev/null` ] || yum install parted
[ `which mdadm    2>/dev/null` ] || yum install mdadm
[ `which xfsprogs 2>/dev/null` ] || yum install xfsprogs

sync && sync && sync                                # folklore, but doesn't hurt

for drive in ${drive_list[@]}; do                   # create new partition label
    echo -e "\tCreating partition label on /dev/sd$drive"
    sudo parted /dev/sd$drive mklabel gpt                                && sync
done

echo -n "press enter to continue > "; read

for drive in ${drive_list[@]}; do                 # create new primary partition
    echo -e "\tCreating new primary partition on /dev/sd$drive"
    sudo parted -a optimal /dev/sd$drive mkpart primary 0% 100%          && sync
done

for drive in ${drive_list[@]}; do                                 # turn on raid
    echo -e "\tactivating RAID on /dev/sd$drive"
    sudo parted /dev/sd$drive set 1 raid on                              && sync
done


# verify drive formatting
for drive in ${drive_list[@]}; do sudo parted /dev/sd$drive print; done

echo "Drive count: $drive_count"
echo "Multi device name: $raid_multi_device"

devicelist=$(eval echo  /dev/sd{`echo "$drive_list" | tr ' ' ,`}1)
echo "Drives: $devicelist"

sudo mdadm  --create \
            --verbose /dev/$raid_multi_device \
            --level=$raid_level \
            --raid-devices=$drive_count $devicelist

# backup the raid multi device so it's persistent on reboot
mkdir -p /etc/mdadm
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf

# ensure the device is assembled on boot
# sudo update-initramfs -u                         # not available on the system
# sudo update-grub              # WATCH OUT! could mess up a separate boot drive
mdadm --verbose --detail -scan > /etc/mdadm.conf       # used to id RAID devices 

sudo mkfs.ext4 -F /dev/$raid_multi_device                # Create the filesystem

sudo mkdir -p /mnt/$raid_multi_device
sudo mount /dev/$raid_multi_device /mnt/$raid_multi_device

# add new mount to fstab
echo "/dev/$raid_multi_device /mnt/$raid_multi_device ext4 defaults,nofail,discard 0 0" | sudo tee -a /etc/fstab

# verify
df -h -t ext4
lsblk
cat /proc/mdstat
sudo mdadm --detail /dev/$raid_multi_device

echo "check the progress of the drive mirroring process with the command: \"cat"
echo " /proc/mdstat\""
```