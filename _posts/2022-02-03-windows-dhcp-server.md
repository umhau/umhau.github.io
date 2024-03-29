---
layout: post
title: Expand the netmask of a Windows DHCP Scope
author: umhau
description: "/24 -> /20"
tags: 
- DHCP
- PowerShell
- Windows Server
- netsh.exe
- Microsoft
categories: walkthroughs
---

I used to wonder why "Micro$oft" was so disliked in the opensource community. Naively, I supposed it had to do with the great evil of demanding money in return for services; or possibly the greater horror of refusing access to source code. But I have learned wisdom before my time, for I have met Active Directory.  What was it Aeschylus said? 

> Even in our sleep, pain which we cannot forget falls drop by drop upon the heart until, in our own despair, against our will, comes wisdom through the awful grace of God.

I need to change the netmask on the dhcp server. My organization has outgrown the /24 allocation it was born with. Easy, right? Just backup a few config files, change a number in a `dhcp.conf`-style textfile and do whatever the windows equivalent of `sh /etc/netstart` is. _Oh, my sweet summer child._

We're dealing with scopes and superscopes: not subnets. We have to export the scope configuration, including DNS and WINS servers, as a semi-executable script. Then we modify the script to use the new netmask. Then we delete the old scope, along with all our DHCP leases and reservations. Then we create a new scope using our exported script.  

Before we go any further, backup the DHCP database. Do this by right-clicking on the root node of the tree in the left-hand bar of the DHCP manager, and select backup, and choose where you want the backup to go.  Don't lose this. 

alternatives
------------

Since I'm just trying to change the netmask, it's also possible to create a superscope and add the current scope. However, this will create two distinct subnets that can't talk to each other, and the gateway will have to have separate ip addresses for each scope. Then you create firewall rules to let the scopes talk to each other. 

It could work, but the communication between the subnets seems like too much complexity and I need to make sure whoever comes after me can understand what's going on. I'd rather just redo the main subnet and keep it dead simple.

doit
----

Export the current scope. We're using `netsh` instead of `Export-DhcpServer`, because I've had situations in the past where I exported to both, but the import failed on the latter and succeeded on the former. Open powershell as an administrator.

```powershell
netsh.exe dhcp server \\DOMAIN_NAME scope 192.168.1.0 dump > C:\scope.txt
```

This gets you a more-or-less executible script that you can modify and then reinsert. Broadly speaking you have to change two things: the scope and the netmask. Just use Ctrl-F and be done with it.

In this example, I'm changing the subnet from 192.168.1.1/24 to 192.168.1.1/20.  

```md
# any octet that varies (determined by the netmask) is set to 0
192.168.1.0 -> 192.168.0.0

# set the netmask to the new value
255.255.255.0 -> 255.255.240.0

# Also look for the command that sets the ip address range.
Add iprange 192.168.1.1 192.168.1.254 -> Add iprange 192.168.1.1 192.168.15.254
```

Once those changes are made, delete the scope from the DHCP manager. _(Yes, I know. But there's no way to back it up besides the export you just made, and at least turning off DHCP doesn't break too many things too quickly.)_  

Then add the new scope by inserting the modified backup. The fun thing is, we can just execute it as a series of `netsh` commands. _(and BTW, that is a weird rabbithole of a program)_  You probably had to save the modified script somewhere else, so change directories inside the cmd prompt first and then execute.

```powershell
cd C:\Users\admin\Documents\
netsh.exe exec scope-modified.txt
```

And activate the scope. 