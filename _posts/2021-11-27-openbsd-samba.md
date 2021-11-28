---
layout: post
title: Samba on OpenBSD
author: umhau
description: "duplication, except that I want to be sure it works on the atypical OS"
tags: 
- Samba
- OpenBSD
categories: walkthroughs
---

Just a quickie - if we have a folder on an OpenBSD machine that we want to share with the local network, what should we use to share it? 
- **sshfs:** this is awesome, if the client is a linux/BSD machine. Don't need to do anything on the host machine, except enable ssh access - and you've already done that, right? 
- **NFS:** you're not serious, right? This fragile system is a pain to set up, horribly slow without custom tuning, and will freeze your _client_ system if you lose the network connection.  Stay away unless you can't, and if you can't, don't depend on it.
- **Samba:** this is actually pretty good. Don't think I've yet had to set up a network that had no windows machines on it, so this is a nice, maximally-compatible protocol. It's fast out-of-the-box, too, so none of the NFS craziness. Also VLC on Android likes it.

So the only one of these three worth a walkthrough is the last, which is the one we're looking at tonight.  The major downside to Samba is, however, the dependencies it pulls in. If you use Samba, you can't consider your system 'clean' anymore. `dbus`? Ewwww....

Install dependencies.

```sh
pkg_add samba
```

Enable the Samba service.

```sh
rcctl enable smbd nmbd
```

Create a folder to share, and make it completely accessible to everyone (the localnet is safe (: )

```sh
mkdir -p /mnt/disk1/public
chown nobody:nobody /mnt/disk1/public
```

Mess with the samba config file. We want a fairly simple setup, so we can just backup the default, and then create a new config from scratch:

```sh
mv /etc/smb.conf /etc/smb.conf.bak
```

```sh
# vim /etc/smb.conf

[global]
   workgroup = WORKGROUP
   server string = Samba Server
   server role = standalone server
   log file = /var/log/samba/smbd.%m
   max log size = 50
   dns proxy = no
   
[shared_folder] 
   path = /mnt/disk1/public 
   writable = yes 
   guest ok = yes 
   guest only = yes 
   create mode = 0777 
   directory mode = 0777
```

Enable Samba.

```sh
rcctl start smbd nmbd
```


