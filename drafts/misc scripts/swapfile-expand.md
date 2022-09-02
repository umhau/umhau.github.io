resize the swapfile (comes default in ubuntu 17.10 and above).

Check swapfile existence and location
    cd /
    ls -lah
turn off the swapfile
    sudo swapoff -a
Resize the swapfile
    sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
Make swapfile usable
    sudo mkswap /swapfile
Make swapon again
    sudo swapon /swapfile


