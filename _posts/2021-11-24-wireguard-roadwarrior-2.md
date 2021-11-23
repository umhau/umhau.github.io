---
layout: post
title: VPN Server
author: umhau
description: "roadwarrior"
tags: 
- wireguard
- OpenBSD
- roadwarrior
- networking
- VPN
categories: walkthroughs
---

**work in progress. easier to read on the blog than in VS code.**

We're going to create a VPN system from pieces. 

We're going to build a VPN server on OpenBSD and give it its own public IP address; write a program to generate keypairs and config files, and zip them up; create a local website that tracks the status of each VPN client's IP address; create a standardized client config, and automate it. 

Tall order, but we got this.

sources
-------

- https://philipdeljanov.com/posts/2019/03/21/setting-up-a-wireguard-vpn/
- https://ianix.com/wireguard/openbsd-howto.html
- https://xosc.org/wireguard.html

VPN parameters
--------------

```sh
VPN subnet range:         10.191.232.1/24
VPN public IP address:    250.123.234.78
VPN external port number: 55667
```

server configuration
--------------------

Do this section all on the OpenBSD server, which should have at least two ethernet ports, one connected to your ISP's router, and the other to your main network.

_(It would be possible to use one machine for the VPN and as the network gatway / firewall / DHCP server / etc, but I'm using OPNSense for that; for the VPN, which hopefully won't have to be touched frequently - or ever - I want OpenBSD. It has an in-kernel wireguard implementation, and its networking configurations are far cleaner, and it should last much longer on its own, if some future sysadmin gets negligent.)_

Wireguard is already installed; there's a set of extra tools we can install so let's do that. And while we're at it let's get some desprately needed utilities on there.

```sh
su
fw_update
export PKG_PATH=http://mirrors.mit.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/
pkg_add -u
pkg_add vim htop nano wireguard-tools
```

The VPN server is going to have its own keypair, and it'll be routing packets, so lets do some preliminaries. I only plan to implement IPV4 routing, so if you need IPV6, you'll have to look elsewhere.

```sh
# enable packet forwarding (server can shuffle packets between ethernet ports)
sysctl net.inet.ip.forwarding=1
echo "net.inet.ip.forwarding=1" >> /etc/sysctl.conf

# set up a folder for wireguard configs
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard
cd /etc/wireguard

# generate the server's private and public keypair
wg genkey > secret.key
chmod 600 secret.key
wg pubkey < secret.key > public.key
```

This config file is going to hold both the server configs, and the info it keeps on each client - which means, we'll be modifying it regularly and programmatically.

```sh
# check what the private key is
cat /etc/wireguard/secret.key

# edit the config file. you'll need the private key
vim /etc/wireguard/wg0.conf
```

This is the first section of what will be a very long file. 
```sh
[Interface]
PrivateKey = <Contents of the server privatekey file>
ListenPort = 55667   
SaveConfig = true    # this lets us permanently add peers to the file via command line
Address = 10.191.232.1/16 
```

The address and subnet of the VPN server. The VPN server will be assigned the specified address, and all clients must be given IPs within this subnet.

client configuration generation (still on the server)
-----------------------------------------------------

We want to be able to generate all the components of a client's config in a separate script. That means we create a keypair associated with an IP address, and have a matching entry in the wg0.conf file on the server. Last step should be that it's wrapped up into a .zip file.

We can add a peer ("client") like this. Note that because we set `SaveConfig = true` above, this will be added directly to the `wg0.conf` that we opened above.  This tells the server what it needs to know to be able to talk to specific, configured clients.  The wgpeer argument, below, is the public key of the _server_.

```sh
ifconfig wg0 \
wgpeer     RF8qxBg7HwWoeGvKzkSh3oV42TG32HT5gVV75k1UWiI= \
wgendpoint 250.123.234.78 55667 \
wgaip      10.191.232.1/24
```

AllowedIPs – The IP address(es) that will be routed through the VPN. In this case, we only want to talk to the server itself, so only the server’s IP address, 172.16.0.1 with the /32 subnet, is specified. Routing entire subnets, or all IPs is also possible by using the proper IP and subnet. For example, if Address is set to 172.16.0.0/16, then all IPs in the range 172.16.0.0 to 172.16.255.255 will be routed through the VPN, useful if you want multiple devices on the same VPN to be able to talk to each other.

```sh
#!/bin/sh
# client config generation script
# in:  client static IP within VPN
# out: zip file

serverpubkey='RF8qxBg7HwWoeGvKzkSh3oV42TG32HT5gVV75k1UWiI='
clientip="$1"
packagename=$clientip.$(date +"%Y.%m.%d.%H.%M.%S") # or: %s seconds since 1970-01-01 00:00:00 UTC

# place to put the new client config
mkdir -p /etc/wireguard/"$packagename"
chmod 700 /etc/wireguard/"$packagename"
cd /etc/wireguard/"$packagename"

# generate the client's private and public keypair
wg genkey > "secret.$clientip.key"
wg pubkey < "secret.$clientip.key" > "public.$clientip.key"



```



networking and packet routing (on the server)
---------------------------------------------

If the port on the firewall isn't opened, OpenBSD's `pf` will just block everything and the VPN will do exactly zip.

```sh
vim /etc/pf.conf
```

```sh
pass in on wg0
pass in inet proto udp from any to any port 51820
pass out on egress inet from (wg0:network) nat-to (vio0:0)
```
(Alternate version)
```sh
# Allow connection to UDP 443
pass in proto udp from any to any port 443 keep state
# NAT the traffic from the wg0 interface
match out on egress from (wg0:network) to any nat-to (egress:0)
```

Verify the pf config after the edit, then add it to the currently running instance of pf.

```sh
pfctl -f /etc/pf.conf -n
pfctl -f /etc/pf.conf
```






