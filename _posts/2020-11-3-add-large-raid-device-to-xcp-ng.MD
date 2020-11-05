---
layout: post
title: add large raid device to xcp-ng
author: umhau
description: "when you need a lot of storage on the hypervisor"
tags: 
- xcp-ng 8.0
- xen
- RAID
- block devices
categories: walkthroughs
---

Warning: this is a really big post, but it does try to be comprehensive within 
its purview.

There's three different ways that a RAID device can be used on a xen or xcp-ng
hypervisor:
1. obviously, a RAID device can be mounted directly on the centos 
substrate, and used via scripts running outside the management consoles; 
2. it can be added as a 'storage repository', which is somewhere that VMs can be
placed; or
3. it can be attached directly to one of the VMs.  
The use-cases for each of these methods are fairly mutually-exclusive; you'll 
have to know ahead of time what you need the drives for. 

There are some strange limitations around the size of large drives, that it 
would be well to be aware of.  If you want to attach a second drive, or 'storage 
repository' to a virtual machine, there's a decision point at the two terabyte 
capacity size: smaller than that, you can create virtual drives within the 
various xcp-ng management consoles and then attach them to the VM: this is the 
standard, GUI-supported mechanism for adding drives. See option two, adding a 
storage repository.  

However, if your VM needs more than a 2TB drive attached 
(say, for a giant NAS) then you'll need to do something different.  The reason
for this difference is in how xcp-ng is built - it still uses EXT3, which has a
maximum file size of around 2TB.  Since a virtual storage repository is 
presented to the hypervisor as a single very large file (think really 
weird zip file), that means the size is capped at 2TB.  Once the developers can 
get around to moving to EXT4 - I understand that's a really big undertaking - 
the limitation will be removed. For now, large drives like that are best 
passed through to the VM directly as 'block devices' and formatted within the 
VM. 

## build the new RAID array

In any case, the first thing to do is clean the drives and create the new RAID 
device. If there's a preexisting RAID device using any of the drives involved,
the partition management commands will not work and it'll probably tell you to
reboot the computer. This is not necessary, will not work, and does not solve
the underlying issue.  Just remove the old RAID device.

The -m argument is the desired name of the new RAID conglomerate drive, or 
'multi-device'.  The -d argument is the drive letters of each drive that should 
either be added to the new RAID device, or removed from the old one. e.g., "c e"
corresponds to "/dev/sdc" and "/dev/sde". Be sure to include the quotation 
marks.

```
bash remove_raid_device.sh -m md0 -d "c e b d"
bash raid-autoconf.sh -r 5 -m md0 -e ext4 -d "c e b d" -c 4
```

I'm including the contents of all the scripts I use at the bottom of this post;
they're also in one of my repositories, but that might change and I might rename
or otherwise alter them. 

## mount directly on the centos hypervisor

Mounting like this is relatively simple, but doesn't really do a lot of good.

While the autoconf script created partitions on the constituents of the RAID 
device, the conglomerate does not have either a partition or a filesystem.  To
create these, run another script:

```
bash format_block_device.sh \
  -d /dev/xyz \
  -f ext4 \
  -t gpt \
  -l partlabel \
  -a /mnt/newdrive
```

This script will perform all the steps between creating the partition table and
ultimately adding the formatted partition to fstab, to be automatically mounted
on boot.


## attach as a storage repository 

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

## attach directly to a virtual machine

This, finally, is the third use of a large drive.  Generally, you can just 
attach USBs with passthrough to a virtual machine. This is sometimes convenient
when you want to, for instance, back up the contents of a VM to a drive you can 
easily physically remove from the server in case of problems.

Warning: this will require a reboot of the hypervisor.

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

And then, just before the end of the file, add these lines:

```
# passthrough the RAID device md0 for attachment to VM
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

The whole file is added at the bottom of this post, with the scripts from 
earlier.

This rule will automatically make the /dev/md0 block device available to be 
attached to any VM on the hypervisor host.  

The autobuild script at the beginning of this post also formatted the drive and
added it to be automatically mounted with fstab.  You'll have to undo that.  Go 
into the fstab and remove the line referencing the /dev/md0 device.

```
nano /etc/fstab
```

Reboot the hypervisor (ugh).  Within XCP-ng Center, go to 'Removable Storage', 
then the 'Storage' tab, and if the device isn't already visible, click 'Scan'. 
The disk should show up as an "Unrecognized bus type". That's OK; notice the 
size of the disk - in my case, with four 2.7TB drives in RAID5, the disk shows
up as 8.2 TB.  

Open up the settings for the VM you want to add it to, and attach the disk. It 
should be persistent accross reboots of the hypervisor - just be careful about
creating a snapshot while it's attached.

Once it's attached to the VM, enter the VM and figure out what the device is. 
Since the drive is new, there will not be a partition scheme on it yet. In that 
case, use 

```
parted -l | grep Error
```

to find a list of `/dev/xyz` drives that cause parted to raise an error because 
they have no partitions. Once the `/dev/xyz` drive is identified, run the 
following script (again, inside the virtual machine) to format the drive and add
it to fstab for automatic mounting. 

```
bash format_block_device.sh \
  -d /dev/xyz \
  -f ext4 \
  -t gpt \
  -l partlabel \ 
  -a /mnt/newdrive
```

Note that "partlabel" should be fairly unique, as this will identify the drive
within fstab for automounting. The last argument, "/mnt/newdrive", is the 
location where the partition should be mounted within the VM operating system.

When that script finishes, the drive will be ready for use. Success!

## scripts

### remove_raid_device.sh

```bash
#!/bin/bash

set -e
set -v

# usage: bash remove_raid_device.sh -m /dev/mdX -d "e v f m"

while getopts ":m:d:" opt; do
  case $opt in
    m) raid_device="$OPTARG" ;;
    d) drive_list="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG. " >&2 ;;
  esac
done

[ -z $raid_device ] && echo "Specify RAID device." && cat /proc/mdstat  && exit
[ -z $drive_list ]  && echo "specify list of drives connected to RAID." && exit

devicelist=$(eval echo  /dev/sd{`echo "$drive_list" | tr ' ' ,`}1)

echo "Drives connected to RAID: $devicelist"
echo -n "Removing RAID device $raid_device. Confirm > "; read

if mount | grep $raid_device > /dev/null; then umount $1; fi

mdadm --stop "$raid_device"                             # deactivate RAID device

mdadm --remove "$raid_device" || true  # remove device - this may sometimes fail

mdadm --zero-superblock $devicelist  # remove superblocks from all related disks

rm -fv /etc/mdadm.conf        # delete file that identifies RAID devices on boot
```

### raid-autoconf.sh

```bash
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
    r) raid_level="$OPTARG" ;;
    m) raid_multi_device="$OPTARG" ;;
    e) filesystemtype="$OPTARG" ;;
    d) drive_list="$OPTARG" ;;
    c) drive_count="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG. " >&2 ;;
  esac
done

[ -z "$raid_level" ]        && echo "raid level not specified."       && exit
[ -z "$raid_multi_device" ] && echo "multidevice not specified."      && exit
[ -z "$filesystemtype" ]    && echo "filesystem type not specified."  && exit
[ -z "$drive_list" ]        && echo "drive list not specified."       && exit
[ -z "$drive_count" ]       && echo "number of drives not specified." && exit

printf "Using RAID %s\n" "$raid_level"
printf "Using /dev/sd[X] drive letters: %s\n" "$drive_list"
printf "Multidevice specified:  /dev/%s\n" "$raid_multi_device"
printf "Filesystem chosen: %s\n" "$filesystemtype"
printf "Number of drives to be formatted: %s\n" "$drive_count"

for drive in ${drive_list[@]}                       # mount-related error checks
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

echo "confirm: using drives ${drive_list[@]} for new RAID $raid_level array."
echo -n "ALL DATA ON ALL LISTED DRIVES WILL BE LOST! > "; read

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

for d in ${drive_list[@]}; do parted /dev/sd$d print; done   # verify formatting

echo -ne "Drive count: $drive_count\nMulti device name: $raid_multi_device\n"

devicelist=$(eval echo  /dev/sd{`echo "$drive_list" | tr ' ' ,`}1)
echo "Drives: $devicelist"

sudo mdadm  --create \
            --verbose /dev/$raid_multi_device \
            --level=$raid_level \
            --raid-devices=$drive_count $devicelist

# backup the raid multi device so it's persistent on reboot
mkdir -pv /etc/mdadm
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

### /etc/udev/rules.d/65-md-incremental.rules

```
KERNEL=="td[a-z]*", GOTO="md_end"
# This file causes block devices with Linux RAID (mdadm) signatures to
# automatically cause mdadm to be run.
# See udev(8) for syntax

# Don't process any events if anaconda is running as anaconda brings up
# raid devices manually
ENV{ANACONDA}=="?*", GOTO="md_end"

# Also don't process disks that are slated to be a multipath device
ENV{DM_MULTIPATH_DEVICE_PATH}=="?*", GOTO="md_end"

# We process add events on block devices (since they are ready as soon as
# they are added to the system), but we must process change events as well
# on any dm devices (like LUKS partitions or LVM logical volumes) and on
# md devices because both of these first get added, then get brought live
# and trigger a change event.  The reason we don't process change events
# on bare hard disks is because if you stop all arrays on a disk, then
# run fdisk on the disk to change the partitions, when fdisk exits it
# triggers a change event, and we want to wait until all the fdisks on
# all member disks are done before we do anything.  Unfortunately, we have
# no way of knowing that, so we just have to let those arrays be brought
# up manually after fdisk has been run on all of the disks.

# First, process all add events (md and dm devices will not really do
# anything here, just regular disks, and this also won't get any imsm
# array members either)
SUBSYSTEM=="block", ACTION=="add", ENV{ID_FS_TYPE}=="linux_raid_member", \
        RUN+="/sbin/mdadm -I $env{DEVNAME}"

# Next, check to make sure the BIOS raid stuff wasn't turned off via cmdline
IMPORT{cmdline}="noiswmd"
IMPORT{cmdline}="nodmraid"
ENV{noiswmd}=="?*", GOTO="md_imsm_inc_end"
ENV{nodmraid}=="?*", GOTO="md_imsm_inc_end"
SUBSYSTEM=="block", ACTION=="add", ENV{ID_FS_TYPE}=="isw_raid_member", \
        RUN+="/sbin/mdadm -I $env{DEVNAME}"
LABEL="md_imsm_inc_end"

SUBSYSTEM=="block", ACTION=="remove", ENV{ID_PATH}=="?*", \
        RUN+="/sbin/mdadm -If $name --path $env{ID_PATH}"
SUBSYSTEM=="block", ACTION=="remove", ENV{ID_PATH}!="?*", \
        RUN+="/sbin/mdadm -If $name"

# Next make sure that this isn't a dm device we should skip for some reason
ENV{DM_UDEV_RULES_VSN}!="?*", GOTO="dm_change_end"
ENV{DM_UDEV_DISABLE_OTHER_RULES_FLAG}=="1", GOTO="dm_change_end"
ENV{DM_SUSPENDED}=="1", GOTO="dm_change_end"
KERNEL=="dm-*", SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="linux_raid_member", \
        ACTION=="change", RUN+="/sbin/mdadm -I $env{DEVNAME}"
LABEL="dm_change_end"

# Finally catch any nested md raid arrays.  If we brought up an md raid
# array that's part of another md raid array, it won't be ready to be used
# until the change event that occurs when it becomes live
KERNEL=="md*", SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="linux_raid_member", \
        ACTION=="change", RUN+="/sbin/mdadm -I $env{DEVNAME}"

# added this to passthrough the /dev/md0 RAID array
KERNEL=="md0", SUBSYSTEM=="block", ACTION=="change", SYMLINK+="xapi/block/%k", \
        RUN+="/bin/sh -c '/opt/xensource/libexec/local-device-change %k 2>&1 >/dev/null&'"

LABEL="md_end"
```

### format_block_device.sh

```bash
#!/bin/bash

set -e
set -v

# this is simple: given a hard drive, wipe it, create a clean partition table, 
# and format it with the chosen filesystem type.

# RUN THIS SCRIPT AS ROOT

# bash format_block_device.sh \
#   -d /dev/xyz \
#   -f ext4 \
#   -t gpt \
#   -l partlabel \
#   -a /mnt/newdrive
#
# d: the device to wipe
# f: the new filesystem type to put on the device
# t: the filesystem table type. gpt recommended, unless compatibility is needed.
# l: partition label. this is used to identify the drive when automounted, so 
#    ensure that it's unique.  It's not as good a system as using the UUID.
# a: the location to auto mount the new drive

while getopts ":d:f:l:a:t:" opt; do
    case $opt in
        d) device="$OPTARG" ;;
        f) fstype="$OPTARG" ;;
        t) table="$OPTARG" ;;
        l) label="$OPTARG" ;;
        a) mountpoint="$OPTARG" ;;
        \?) echo "Invalid option -$OPTARG. " >&2 ;;
    esac
done

[ -z "$device" ] && echo "raid level not specified."          && exit
[ -z "$fstype" ] && echo "new filesystem type not specified." && exit
[ -z "$table" ]  && echo "filesystem table type not given."   && exit
[ -z "$label" ]  && echo "partition label not given."         && exit
[ -z "$mountpoint" ] && echo "mount point of new partition not given." && exit

if mount | grep -q $device > /dev/null
then 
    echo "ERROR: $drive is mounted."
    exit
elif mount | grep $mountpoint > /dev/null
then
    echo "$mountpoint in use."
    exit
elif cat /proc/mdstat | grep $device > /dev/null
then
   echo "ERROR: $device is in a RAID device, remove before proceeding."
   exit 
elif [ `whoami` != "root" ]
then 
    echo "run this script as root!"
    exit
fi

echo "device to wipe: $device"
echo "new filesystem: $fstype"
echo "partition table: $table"
echo "partition label: $label"
echo -n "Confirm > " && read

[ `which parted   2>/dev/null` ] || apt install parted
[ `which mkfs     2>/dev/null` ] || apt install util-linux

parted $device mklabel $table && sync               # create new partition table

parted -a optimal $device mkpart primary 0% 100% && sync # new primary partition

partition="$device"1                                # new variable for /dev/xyz1

if ! partprobe -d -s $partition &>/dev/null                  # check for success
then
    echo "partition MISSING"
    exit
fi

mkfs.$fstype -L $label $partition       # create the filesystem on the partition

mkdir -pv $mountpoint                                     # make the mount point

cp /etc/fstab /etc/fstab.$(date +"%FT%H%M%S").bak            # back up the fstab

# fs_uuid=$(lsblk -no UUID $partition)                 # get the filesystem UUID
# using the UUID would be better, but then there's no way to detect duplicates
# echo "UUID="$fs_uuid" $mountpoint $fstype defaults 0 2" >> /etc/fstab

# if the script has already been run, remove the extra fstab entry
if grep $label /etc/fstab; then sed "/$label/d" /etc/fstab > /etc/fstab; fi

echo "LABEL=$label $mountpoint $fstype defaults 0 2" >> /etc/fstab   # automount

mount -a        # mount everything listed in the fstab - errors will be revealed

lsblk #-o NAME,FSTYPE,LABEL,UUID,MOUNTPOINT  # view the partition and filesystem

cat /etc/fstab                             # check for superfluous fstab entries

if mount | grep -q $mountpoint > /dev/null; then echo "SUCCESS"; fi
```