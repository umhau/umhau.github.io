---
layout: post
title: Install the Ubiquiti network controller
author: umhau
description: "better than the official version"
tags: 
- Ubiquiti
- Ubuntu
- sysadmin
- networking
- unifi
- wifi network controller
categories: walkthroughs
---

The official docs are a royal pain, and didn't actually work that great when I tried them. This did. 

I used an ubuntu server virtual machine on my hypervisor for this. First step, `ssh` into that virtual machine. 

```
ssh username@ip-address
```

Remember that IP address. You'll need it to access the controller interface when you're done.

### installation

Install java.

```
sudo apt-get update
sudo apt-get install openjdk-8-jre-headless
java -version
```

Pull down the unifi package into the `/tmp/` folder and install it.

```
cd /tmp/
wget https://dl.ui.com/unifi/6.0.22/unifi_sysvinit_all.deb
sudo apt-get install ./unifi_sysvinit_all.deb
cd
```

When that finishes, the controller should be installed and working.  Access the network interface: 

```
https://ip-address-of-server:8443
```

### Some useful commands

To start UniFi if the webpage prompt does not appear:
```
sudo service unifi start
```
To stop the UniFi service:
```
sudo service unifi stop
```
To restart the UniFi service:
```
sudo service unifi restart
```
To see the status of UniFi service:
```
sudo service unifi status
```

### source

[https://gist.github.com/codeniko/381e8be3b0236a602e02f0a9fac13b3d](https://gist.github.com/codeniko/381e8be3b0236a602e02f0a9fac13b3d)
