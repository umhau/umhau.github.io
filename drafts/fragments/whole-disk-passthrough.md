My Preferred Approach to XenServer Whole Disk Passthrough

I therefore have settled on option (3) as my preferred method. Option (3) is basically a manual version of option (2) where you also create your own storage repository for the disk. Option (3) was offered by the user “makstex” in a comment on the same post at http://techblog.conglomer.net/sata-direct-local-disk-access-on-xenserver/#comment-6404. Option (3) requires running the following commands from the XenServer host shell.
1
	mkdir /srv/YOUR_SR_NAME
2
	xe sr-create name-label=”MY BLOCK SR” name-description=”MY BLOCK SR” type=udev content-type=disk device-config:location=/srv/YOUR_SR_NAME
3
	ln -s /dev/sdb /srv/YOUR_SR_NAME/sdb
4
	xe sr-scan uuid=YOUR_NEW_UUID
5
	xe vdi-list sr-uuid=YOUR_NEW_UUID

The actions in the lines above are:

    Create a new directory under /srv for your new storage repository. You can choose another directory location if you prefer.
    Create a new Storage Repository (SR) with the name of your choosing that points to the directory you just created
    Create a soft link from the /dev entry for your disk to the directory of the SR
    Tell XenServer to scan the new repository
    List the disks in the new repository

You can now use the XenCenter GUI or other management tool to add the disk in the SR to the VM of your choice. I have tested this and the storage repository and mapping persist across reboots. However, the configuration won’t persist across all upgrades to make sure and document this so you can put it back after an upgrade.

I can say that the performance in this configuration is pretty close to theoretical maximums for the disk in my testing. The other peace of mind I have is that if the XenServer host gives up the ghost, I can take this disk as is and put it in another server to read from the filesystem on the disk directly.

https://www.zerodispersion.com/xenserver-whole-disk-passthrough/

## WHEN I DID IT

```
[20:08 daniel ~]# ls /srv/
[20:08 daniel ~]# mkdir /srv/WIN_XP
[20:08 daniel ~]# xe sr-create name-label=”WIN_XP_BLOCK_SR” name-description=”WIN_XP_BLOCK_SR” type=udev content-type=disk device-config:location=/srv/WIN_XP
528b1453-78c4-06f3-938e-3b2ed231c41e
[20:09 daniel ~]# ln -s /dev/sdk /srv/WIN_XP/sdk
[20:09 daniel ~]# xe sr-scan uuid=528b1453-78c4-06f3-938e-3b2ed231c41e
[20:10 daniel ~]# xe vdi-list sr-uuid=528b1453-78c4-06f3-938e-3b2ed231c41e
uuid ( RO)                : 7301da29-c57a-4943-b526-8ed94f3b1fe2
          name-label ( RW): SCSI 0:0:10:0
    name-description ( RW): ATA model ST3250310AS rev A type 0
             sr-uuid ( RO): 528b1453-78c4-06f3-938e-3b2ed231c41e
        virtual-size ( RO): 250000000000
            sharable ( RO): false
           read-only ( RO): false


[20:10 daniel ~]#
```
