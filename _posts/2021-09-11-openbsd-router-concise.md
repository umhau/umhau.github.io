---
layout: post
title: OpenBSD Router, 2nd draft
author: umhau
description: "short version"
tags: 
- OpenBSD
- networking
- UNIX
- router
- NAT
- PF
- DHCP
- DNS
- firewall
- unbound
categories: walkthroughs
---

Welcome back to the thunderdome: a one-stop-shop to get your brain thoroughly bashed with incomprehensible ideas and ineffable concepts.

That is to say, welcome back to the OpenBSD router discussion. This is the short version: a bit of interstitial text, but mostly just a place to put all the separate config files and scripts that need to be synchronized.

We assume this is a fresh installation of OpenBSD 6.9 on a dedicated physical box which has separate ethernet ports for each subnet and the egress point.

When each of the following pieces have been added, reboot the router.  That's the simplest way to get everything started properly.

# network design

```
                      0.0.0.0/0
+-----------------------------+
| open internet               |
+-+---------------------------+
  |
  |
  |                 123.12.23.2
+-+---------------------------+
| ISP-assigned router         |
| device: em2                 |
+-+---------------------------+
  |
  |
  |               192.168.1.102
+-+---------------------------+
| firewall / router           |
| (OpenBSD)                   |
+-+--+------------------------+
  |  |
  |  |
  |  |                 10.0.1.1/24   +------------+-----------------------+
  |  |  +------------------------+   |            |                       |
  |  +--+ (insecure network)     +---+   +--------+---------+  +----------+----------+
  |     | device: em0            |       |wifi access points|  |laptops, servers, etc|
  |     +------------------------+       +------------------+  +---------------------+
  |
  |
  |                    10.0.2.1/24   +------------+-----------------------+
  |     +------------------------+   |            |                       |
  +-----+ (secure network)       +---+   +--------+---------+  +----------+----------+
        | device: em1            |       |wifi access points|  |laptops, servers, etc|
        +------------------------+       +------------------+  +---------------------+
```

Note, depending on the OpenBSD firewall/router box configuration, there can also be virtual machines inside that box which are connected to one or more of the subnets. 

The router will have an ip address on each of the subnets; this is referred to as the 'gateway address', since the router is literally a gateway out of the sub-network.  That IP address is usually the first in the available series: i.e., 100.100.1.1 and 100.100.2.1 in the two examples above.

I like having the wireless clients on the same subnet as the wired clients, but that's my use case. It can be nearly as easy to put all the wifi APs on their own subnet.

# router construction

Allow packets to be forwarded between network devices on the OpenBSD machine.

```sh
echo 'net.inet.ip.forwarding=1' > /etc/sysctl.conf
```

Request an IP address using DHCP for the network device port connected to the open internet (`em2`).

```sh
echo 'dhcp' > /etc/hostname.em2
```

It should (IIRC) now be possible to get online now by restarting the system network connections with the new configuration.

```sh
sh /etc/netstart
```

Define the subnets provided by each network device port.

```sh
echo 'inet 10.0.0.1 255.255.255.0 10.0.0.255 description   "secure network"' > /etc/hostname.em0
echo 'inet 10.0.1.1 255.255.255.0 10.0.1.255 description "insecure network"' > /etc/hostname.em1
```

## DHCP (IP address assignment)

Start the `dhcpd` daemon, and tell it which network device ports will need the dhcp service available.

```sh
rcctl enable dhcpd
rcctl set dhcpd flags em0 em1
```

Modify the dhcpd config file.

### /etc/dhcpd.conf

```sh
option domain-name "ninthiteration.lab";

subnet 10.0.0.0 netmask 255.255.255.0 {
        option routers 10.0.0.1;
        option domain-name-servers 10.0.0.1;
        range 10.0.0.10 10.0.0.254;
}
subnet 10.0.1.0 netmask 255.255.255.0 {
        option routers 10.0.1.1;
        option domain-name-servers 10.0.1.1;
        range 10.0.1.10 10.0.1.254;
}
```

## PF (firewall)

An exhaustive (believe me, it was exhausting to make) explanation of the contents of this file is in the longer version of this post. 

### /etc/pf.conf

```sh
secure   = "em0"
insecure = "em1"

table <martians> { 0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16     \
                   172.16.0.0/12 192.0.0.0/24 192.0.2.0/24 224.0.0.0/3 \
                   192.168.0.0/16 198.18.0.0/15 198.51.100.0/24        \
                   203.0.113.0/24 }

set block-policy drop
set loginterface egress
set skip on lo0

match in all scrub (no-df random-id max-mss 1440)
match out on egress inet from !(egress:network) to any nat-to (egress:0)

antispoof quick for { egress $secure $insecure }
block in quick on egress from <martians> to any
block return out quick on egress from any to <martians>
block all

pass out quick inet
pass in on { $secure $insecure } inet
```

## DNS

Enable the `unbound` DNS daemon.

```sh
rcctl enable unbound
```

The unbound daemon puts itself in a chroot after starting, so its config file is buried a little deeper than the others. 

### /var/unbound/etc/unbound.conf

```sh
server:
    interface: 10.0.0.1
    interface: 10.0.1.1
    interface: 127.0.0.1

    access-control: 0.0.0.0/0   refuse
    access-control: 10.0.0.1/24 allow
    access-control: 10.0.1.1/24 allow
    do-not-query-localhost: no
    hide-identity: yes
    hide-version: yes

forward-zone:
        name: "."
        forward-addr: 192.168.43.79  # IP of the upstream resolver
```

## Nameserver

We want router to use its own unbound DNS cache.

### /etc/resolv.conf

```sh
nameserver 127.0.0.1
nameserver 192.168.43.79
```

Problem is, this gets overwritten every time dhcp runs, because part of the dhcp protocol is a record of the server which provided the IP address. We have our own such server, and we want to use it instead.

### /etc/dhclient.conf

```sh
interface "em2" { 
    ignore domain-name-servers; 
}
```
