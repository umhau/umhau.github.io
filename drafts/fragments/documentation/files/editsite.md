### Edit via command line:

    ssh user@ipaddr
    cd documentation/files
    vim index.md

    cd ~/documentation
    sh updatesite.sh

### Mount locally:

    sudo mkdir -p /net/docsite
    sudo chmod 777 /net/docsite

    sshfs -o allow_root,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 user@ipaddr:. /net/docsite/

Now the files can be accessed with a proper text editor. Note that running the `updatesite.sh` script will still require ssh access.
