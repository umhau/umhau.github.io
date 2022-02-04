This time it's samba on FreeBSD.

```sh
pkg search samba
pkg install samba413
```

Create somewhere to share files from.

```sh
mkdir -pv /shares/data
chmod -R 777 /shares
chown -R nobody:nobody /shares
```

Create a config file.

```sh
vim /usr/local/etc/smb4.conf
```

```
[global]
   workgroup = WORKGROUP
   server string = Samba Server
   server role = standalone server
   log file = /var/log/samba4/smbd.%m
   max log size = 50
   dns proxy = no
   
[shared_folder] 
   path = /shares/data 
   writable = yes 
   guest ok = yes 
   guest only = yes 
   create mode = 0777 
   directory mode = 0777
```

Enable and start the samba service.

```sh
sysrc samba_server_enable=YES
service samba_server start

# echo "smbd_enable=\"YES\"" >> /etc/rc.conf
```

And you're done.