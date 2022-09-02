---
layout: post
title: OpenBSD Router, 3rd draft
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

And here we go again. The problem with the previous configuration is that DNS doesn't work: you can ping any IP address you like across the open internet, but URLs weren't being resolved. That is, `ping 1.1.1.1` works fine, but `ping google.com` failed completely.

So this is a variation that focuses on unbound. The rest of the settings and architecture are included, because unbound does not exist in a vaccume - but they're just a sideshow.

As before, we assume this is a fresh installation of OpenBSD 6.9 on a dedicated physical box which has separate ethernet ports for each subnet and the egress point.

We're using another source: https://openbsdrouterguide.net/#dns-hijacking.

Looks like there's a specific domain I should use for my local network, since I haven't registered one properly: `.home.arpa`. Guess that's a holdover from the early days. 

> Some people recommend that you register a domain name and then use that internally on your LAN, and while that certainly works, it is not necessary at all. According to the RFC 8375 you should use the .home.arpa domain as this is meant to be used inside a small network, such as a home network.



# network design

Nonstandard diagram, but might be a little less obtuse than the standard. 

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

Preliminaries.

```sh
echo 'net.inet.ip.forwarding=1' > /etc/sysctl.conf
```

```sh
echo 'dhcp'                                                                  > /etc/hostname.em2
echo 'inet 10.0.0.1 255.255.255.0 10.0.0.255 description   "secure network"' > /etc/hostname.em0
echo 'inet 10.0.1.1 255.255.255.0 10.0.1.255 description "insecure network"' > /etc/hostname.em1
```

## DHCP (IP address assignment)

Start the `dhcpd` daemon, and tell it which network device ports will need the dhcp service available.

```sh
rcctl enable dhcpd
rcctl set dhcpd flags em0 em1
```

### /etc/dhcpd.conf

```sh
option domain-name "home.arpa";

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

### /etc/pf.conf

```sh
secure   = "em0"
insecure = "em1"
external = "em2"

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
# pass out on $external inet from $secure:network   to any nat-to ($external)
# pass out on $external inet from $insecure:network to any nat-to ($external)

pass in on { $secure $insecure } inet
```

## DNS

Enable the `unbound` DNS daemon.

```sh
rcctl enable unbound
```

Create an unbound-specific log file. 

```sh
mkdir /var/unbound/log
touch /var/unbound/log/unbound.log
chown -R root._unbound /var/unbound/log
chmod -R 774 /var/unbound/log
```

### /var/unbound/etc/unbound.conf

```sh
server:

    # Logging (default is no).
    # Uncomment this section if you want to enable logging.
    # Note enabling logging makes the server (significantly) slower.
    # verbosity: 2
    # log-queries: yes
    # log-replies: yes
    # log-tag-queryreply: yes
    # log-local-actions: yes
    # logfile: "/log/unbound.log"
    # use-syslog: no
    # log-time-ascii: yes

    interface: 127.0.0.1
    interface: 10.0.0.1
    interface: 10.0.1.1

    # Control who has access.
    access-control: 0.0.0.0/0 refuse
    access-control: ::0/0 refuse
    access-control: ::1 allow

    access-control: 127.0.0.0/8 allow
    access-control: 10.0.0.0/24 allow
    access-control: 10.0.1.0/24 allow

    # "id.server" and "hostname.bind" queries are refused.
    hide-identity: yes

    # "version.server" and "version.bind" queries are refused.
    hide-version: yes

    # Cache elements are prefetched before they expire to keep the cache up to date.
    prefetch: yes

    # Our LAN segments.
    private-address: 10.0.0.0/16
    
    # local domain
    private-domain: home.arpa

    # otherwise unbound tries to get DNS info from IPV6 addresses:
    # "info: error sending query to auth server"
    do-ip6: no

    # save cached lookups for way longer than I should
    #   3600 = 1 hour
    #  86400 = 1 day
    # 604800 = 1 week
    cache-min-ttl: 604800
    serve-expired: yes

    # use an updated root hints file
    root-hints: "/var/unbound/etc/named.cache"

    # We want DNSSEC validation.
    # auto-trust-anchor-file: "/var/unbound/db/root.key"

# Enable the usage of the unbound-control command.
remote-control:
    control-enable: yes
    control-interface: /var/run/unbound.sock
```


## Nameserver

We want the router to use its own unbound DNS cache.

### /etc/resolv.conf

```sh
nameserver 127.0.0.1
# nameserver 192.168.43.79

echo "nameserver 127.0.0.1" > /etc/resolv.conf
```

Problem is, this gets overwritten every time dhcp runs, because part of the dhcp protocol is a record of the server which provided the IP address. We have our own such server, and we want to use it instead.

### /etc/dhclient.conf

```sh
interface "em2" { 
    ignore domain-name-servers; 
}
```
