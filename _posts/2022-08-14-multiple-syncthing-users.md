---
layout: post
title: Syncthings
author: umhau
description: "Multiple Users"
tags: 
- syncthing
- FreeBSD
- ports
- networking
- shell
- zerotier
- NAT punching
categories: walkthroughs
---

Syncthing is this cool program that is basically Dropbox Unlimited (tm): everything is only on your own server (except the NAT punching and where-are-you stuff), and your space is limited only by the storage on your devices. 

I want to set up a syncthing NAS. But, I want to make it available to two separate people, each with their own accounts. And I want to do it on FreeBSD.  And I want to manage it remotely.

That means, we're also using a program called zerotier. You know how it's easier to talk to machines that are connected to the local network? This is a tiny program you install on machines around the world, you share a key with each, and then they can all see each other as if they're on the same local network. 

I need to put that on the FreeBSD machine as well, so that I can access the management GUI without fragile port forwarding. The goal is that this machine can be plugged in anywhere, turned on, attached to an ethernet cable, and get right down to business. 

We're doing this from a fresh FreeBSD installation. 

installations
-------------

The trick to multple syncthing users on a single machine is, literally, multiple users. I thought I'd need jails or some such, but as it turns out, all we need are to create new users. Here, I'm using `usr1` and `usr2`.

I did that during the install process, so I won't document the manual user creation process here. Go google it if you don't know how. 

Become root, if you aren't already.

    su

Perform the initial system updates. This will take a while.

    freebsd-update fetch
    freebsd-update install

Install the packages we need. 

    pkg install syncthing zerotier nano tmux vim htop 

Do you have a zerotier account? Because you'll need one. Unless you want to selfhost the sync servers; but that's a project for another day. [Go get one](https://www.zerotier.com/download/), and set up a network. Then come back.

configurations
--------------

### cron

Use cron to start two separate instances of syncthing on boot: one owned by user `usr1`, and the other owned by user `usr2`. 

    su
    crontab -e

    @reboot su - usr1 -c /usr/local/bin/syncthing
    @reboot su - usr2 -c /usr/local/bin/syncthing
    @reboot zerotier-one -d

After we (eventually) reboot, we can use `top` (or `htop`) to see the two syncthing instances running.

### zerotier

Start zerotier.

    zerotier-one -d

Go get the id for the network you want to join this machine to. If you got yourself a zerotier account, you'll know what I'm talking about.

    zerotier-cli join 012d30m32bkjqqewr

### pf

Enable the pf firewall: we need to manually adjust what we're allowing through the system.

    sysrc pf_enable=yes
    sysrc pflog_enable=yes

Then create a new firewall config file. 

    nano /etc/pf.conf

```pf
ex_if = "em0"
zt_if = "zta098fdas123ij"

set skip on lo0
scrub in

block in
pass out

pass in on $ex_if proto tcp from any to ($ex_if) port { ssh, domain, http, https, 22001, 22002, 8385, 8386 }
pass in on $zt_if proto tcp from any to ($zt_if) port { ssh, domain, http, https, 22001, 22002, 8385, 8386 }

pass in on $ex_if proto udp to ($ex_if) port { domain, 22001, 22002, 8385, 8386 }
pass in on $zt_if proto udp to ($zt_if) port { domain, 22001, 22002, 8385, 8386 }

pass in on $ex_if proto udp to any port { mdns, 21028, 21029 }
pass in on $zt_if proto udp to any port { mdns, 21028, 21029 }

pass in on $ex_if inet proto icmp to ($ex_if) icmp-type { unreach, redir, timex, echoreq }
pass in on $zt_if inet proto icmp to ($zt_if) icmp-type { unreach, redir, timex, echoreq }
```

Note that the `zt_if` variable will be different for you - you'll have to get it by running `ifconfig` and seeing what the zerotier interface actually is. 

### syncthing

Note that in both examples above, we have opened several custom ports. By default, syncthing wants to use port 8384 to host the GUI and uses port 22000 for everything else (TCP and UDP, in case you know what that means). We need to adjust these, and we'll have to use the command line.

Summary of changes: 

    usr1
    port 22001
    port 8385
    port 21028

    usr2
    port 22002
    port 8386
    port 21029

    GUI
    0.0.0.0

So. Become the user.

    su usr1

Start syncthing, let it initialize, and then kill it with `CTRL-C`.

    syncthing

Open the syncthing config file. 

    cd
    nano .config/syncthing/config.xml

Now you'll have to modify several points in this (rather long) file. They will look similar to the sections below. Since we are `usr1`, the following are the changes we must make.

    usr1
    port 22001
    port 8385
    port 21028

```XML
<gui enabled="true" tls="true" debugging="false">
    <address>127.0.0.1:8384</address>
    <user>usr1</user>
    ⋮
</gui>
```

```XML
<options>
    <listenAddress>default</listenAddress>
    ⋮
    <localAnnouncePort>21027</localAnnouncePort>
    <localAnnounceMCAddr>[ff12::8384]:21027</localAnnounceMCAddr>
    ⋮
</options>
```

Alter the above to match the below. 

```XML
<gui enabled="true" tls="true" debugging="false">
    <address>0.0.0.0:8385</address>
    <user>usr1</user>
    ⋮
</gui>
```

The `0.0.0.0` indicates that we want to access the GUI from the rest of the local network; otherwise, we'd have to physically log into that machine running syncthing in order to get to the GUI.

```XML
<options>
    <listenAddress>22001</listenAddress>
    ⋮
    <localAnnouncePort>21028</localAnnouncePort>
    <localAnnounceMCAddr>[ff12::8385]:21028</localAnnounceMCAddr>
    ⋮
</options>
```

Now exit from `usr1`, become `usr2`, and perform the simlilar set of substitutions with the `usr2` settings. 

    usr2
    port 22002
    port 8386
    port 21029

cleanup
-------

Get the ip address of the syncthing host. 

    ifconfig

And reboot. If you did everything correctly, syncthing will automatically startup with the machine.  You can access the GUI for each of the syncthing users with the IP address you just obtained, and the GUI port appended:

    http://123.456.789.000:8385
    http://123.456.789.000:8386

Not only that, but you can also use the IP address of the machine that's available through zerotier. That gives you global, secure access. From there you can connect each instance to whatever accounts you want.
