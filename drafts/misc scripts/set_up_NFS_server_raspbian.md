### sources

https://www.raspberrypi.org/forums/viewtopic.php?t=14500
https://www.cyberciti.biz/faq/how-to-ubuntu-nfs-server-configuration-howto/

### installation

    sudo apt-get install nfs-kernel-server nfs-common

    sudo nano /etc/exports

contents of /etc/exports:

    /mnt/AS_V3/music 192.168.1.0/24(ro,sync) umhau(rw,fsid=0,insecure,no_subtree_check,async)

then run: 

    sudo /etc/init.d/nfs-kernel-server restart

to access the folder

    sudo apt install nfs-common
    mkdir /mnt/music
    sudo chown umhau:umhau /mnt/music
    sudo mount eight:/mnt/AS_V3/music /mnt/music

    


