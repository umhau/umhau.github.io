random useful stuff
===================

mount a drive
-------------

    after plugging it in, look for sdX in the blue information text. 
    then create a folder in /mnt and mount the drive there.  You can 
    usually assume the partition on the drive will be 'i'. Thus:
    $ mkdir /mnt/flashdrive
    $ mount /dev/sd1i /mnt/flashdrive
    Also note that the drive must be EXT2; EXT4 and NTFS are not 
    compatible with openBSD.

directory size
--------------
    $ du -sh /directory


