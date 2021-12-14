---
layout: post
title: Lighttpd on FreeBSD (short, insecure version)
author: umhau
description: "quick and dirty version"
tags: 
- lighttpd
- FreeBSD
- html
- webserver
categories: walkthroughs
---

It's super useful to be able to make simple, local websites. This is just a quick and dirty thing that gets an `index.html` on the local net ASAP.  I'll make a longer version of this post for when I need something that's safe to put on the internet.

[Source](https://redmine.lighttpd.net/projects/lighttpd/wiki/TutorialConfiguration). [Additional info](https://redmine.lighttpd.net/projects/lighttpd/repository/14/revisions/master/entry/doc/config/lighttpd.conf).

Get those deps.

```sh
su -m root -c 'pkg install lighttpd vim'
```

Let's make a folder in the home directory with our installation stuff, configs, and master copy of our website data.

```sh
mkdir -p ~/website
cd ~/website
```

Also make a folder for the live version of the website to live in. It will need to be globally readable and executable, but no one needs write permission but the owner.

```sh
su -m root -c 'mkdir -p /var/www/servers/documentation/pages/'
chown -R `whoami`:`whoami` /var/www/servers/documentation
chmod -R 755 /var/www/servers/documentation
```

Create a config file for lighttpd, then put the following lines in it.

```sh
vim ~/website/lighttpd.conf
```
```sh
server.document-root = "/var/www/servers/documentation/pages/" 

server.port = 80

server.username = "www" 
server.groupname = "www" 

mimetype.assign = (
  ".html" => "text/html", 
  ".txt" => "text/plain",
  ".jpg" => "image/jpeg",
  ".png" => "image/png" 
)

static-file.exclude-extensions = ( ".fcgi", ".php", ".rb", "~", ".inc" )
index-file.names = ( "index.html" )
```

Make sure the config doesn't have errors.

```sh
lighttpd -tt -f ~/website/lighttpd.conf
```

Make a simple website:

```sh
echo 'hello' > /var/www/servers/documentation/pages/index.html
```

You can start the server by hand.

```sh
su
lighttpd -D -f ~/website/lighttpd.conf
exit
```

Or enable the daemon that starts the server with the machine.

```sh
su
echo 'lighttpd_enable="YES"' >> /etc/rc.conf
exit
```

Then reboot, and the server is running. If you don't want to reboot, start it manually.

```sh
su
/usr/local/etc/rc.d/lighttpd start
```

Verify that it's running.

```sh
netstat -nat
```

The firewall will prevent the server from being accessed outside the local machine.