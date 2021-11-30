---
layout: post
title: An ergonomic, yet simple, roadwarrior VPN server for a small group
author: umhau
description: "roadwarrior"
tags: 
- wireguard
- OpenBSD
- roadwarrior
- networking
- VPN
- lighttpd
categories: walkthroughs
---

**work in progress. easier to read on the blog than in VS code while I'm building it.**

We're going to build a VPN server on OpenBSD and give it its own public IP address; write a program to generate keypairs and config files, and zip them up; create a local website that tracks the use/disuse status of each VPN client's IP address; create a standardized client config; and automate the whole thing so it's autonomous for years at a stretch. 

Tall order, but we got this.

sources
-------

- https://philipdeljanov.com/posts/2019/03/21/setting-up-a-wireguard-vpn/
- https://ianix.com/wireguard/openbsd-howto.html
- https://xosc.org/wireguard.html

VPN parameters
--------------

We're using this example config everywhere. I won't bother to use variables or mention it again; just pay attention and swap these numbers out when you see them.

```sh
VPN subnet range:         10.191.232.1/24
VPN public IP address:    250.123.234.78
VPN external port number: 55667
```

architecture components
-----------------------

```
[clients.csv]  list of all current client configs - ip address and private key
[genclient.sh] given an ip address, creates and inserts a complete client config
[pf.conf]      OpenBSD firewall config; must modify to allow VPN traffic through
[wg0.conf]     Tells wireguard what settings to use for the VPN
```

server configuration
====================

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

install and prepare wireguard
-----------------------------

The VPN server is going to have its own keypair, and it'll be routing packets, so lets do some preliminaries. I only plan to implement IPV4 routing, so if you need IPV6, you'll have to look elsewhere.

```sh
# enable packet forwarding (server can shuffle packets between ethernet ports)
sysctl net.inet.ip.forwarding=1
echo "net.inet.ip.forwarding=1" >> /etc/sysctl.conf

# set up a folder for wireguard configs (we want the webserver to have access to this)
mkdir -p /etc/wireguard
chmod 744 /etc/wireguard
cd /etc/wireguard

# generate the server's private and public keypair
wg genkey > secret.key
wg pubkey < secret.key > public.key
chmod 600 secret.key
chmod 644 public.key
```

create the server-side wireguard configuration file
---------------------------------------------------

This config file is going to hold both the server configs, and the info it keeps on each client - which means, we'll be modifying it regularly and programmatically.  It's funny, though, because there's nothing inherently different about the server config than the client configs - in both cases, we're just describing the network from the perspective of the owner of the config file.

```sh
# check what the private key is
cat /etc/wireguard/secret.key

# edit the config file (you'll need the private key)
vim /etc/wireguard/wg0.conf
```

This is the first section of what will be a very long file; the rest will similarly describe each connected (or potentially connected) `[peer]`. 

```sh
echo "[Interface]"                             >> /etc/wireguard/wg0.conf
echo "PrivateKey = $serverprivatekey"          >> /etc/wireguard/wg0.conf
echo "ListenPort = $serverportnum"             >> /etc/wireguard/wg0.conf
echo "SaveConfig = true"                       >> /etc/wireguard/wg0.conf
echo "Address    = $serverVPNip/$subnetrange"  >> /etc/wireguard/wg0.conf
```

We can add a peer ("client") to the server like this.  This tells the server what it needs to know to be able to talk to specific, configured clients.  

```sh
echo "[Peer]"                                  >> /etc/wireguard/wg0.conf
echo "PublicKey  = $clientpubkey"              >> /etc/wireguard/wg0.conf
echo "AllowedIPs = $serverip/$subnetrange"     >> /etc/wireguard/wg0.conf
```

> AllowedIPs – The IP address(es) that will be routed through the VPN. In this case, we only want to talk to the server itself, so only the server’s IP address, 172.16.0.1 with the /32 subnet, is specified. Routing entire subnets, or all IPs is also possible by using the proper IP and subnet. For example, if Address is set to 172.16.0.0/16, then all IPs in the range 172.16.0.0 to 172.16.255.255 will be routed through the VPN, useful if you want multiple devices on the same VPN to be able to talk to each other.

> What is the AllowedIPs config line? It specifies that packets destined for these IP addresses go over WireGuard. IPs not in the list don't get sent over WireGuard. Here, 0.0.0.0/0 and ::/0 mean all IP addresses in IPv4 and IPv6, respectively.

open the firewall
-----------------

Gotta open a hole in the firewall to let the VPN through. Add the following lines to the Packet Filter config file

```sh
# vim /etc/pf.conf
pass in on wg0
pass in inet proto udp from any to any port 55667
pass out on egress inet from (wg0:network) nat-to (vio0:0)
```


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

Only a single line is strictly necessary in pf.conf, but of course feel free to keep your other pf rules:
```sh
pass out on egress inet from (wg0:network) nat-to (vio0:0)
```
https://ianix.com/wireguard/openbsd-howto.html



client configuration
====================

We want to be able to generate all the components of a client's config and put it in a separate script. That means, if we want to generate it programmatically, it has to be done on the server where the primary configs are - the 'source of truth'.  Also note that we're doing this before we actually know what client the config will be used in - might be a linux box, will probably be a windows machine - so the only identifying characteristics are the private keys (keep those safe!) and the assigned / recorded IP addresses.

Grab some variables.

```sh
serverpubkey="$2"
clientip="$1"
serverendpointip='250.123.234.78'
serverportnum='55667'
subnetrange='24'
serverip='10.191.232.1'
```

Generate a new private key for the client config, and derive from that a public key. 

```sh
wg genkey > "secret.$clientip.key"
wg pubkey < "secret.$clientip.key" > "public.$clientip.key"
```

Now the fun part: create a config file for the client. This is the same sort of file as the server's, but pointed the other way: it initiates the connection, and always knows where to get in contact with the single peer it has a record of. Contrast to the server, which knows about a lot of different peers, but has no idea where to contact them, and so just waits for incoming connections.

```sh
echo "[Interface]"                                             >> "wireguard.$clientip.conf"
echo "Address    = $clientip"                                  >> "wireguard.$clientip.conf"
echo "PrivateKey = $privatekey"                                >> "wireguard.$clientip.conf"
echo "ListenPort = $serverportnum"                             >> "wireguard.$clientip.conf"
echo ""                                                        >> "wireguard.$clientip.conf"
echo "[Peer]"                                                  >> "wireguard.$clientip.conf"
echo "PublicKey  = $serverpubkey"                              >> "wireguard.$clientip.conf"
echo "Endpoint   = $serverendpointip:$serverportnum"           >> "wireguard.$clientip.conf"
echo "AllowedIPs = $serverip/$subnetrange"                     >> "wireguard.$clientip.conf"
echo "PersistentKeepalive = 25"                                >> "wireguard.$clientip.conf"
```

And that's it! Notice that all the critical information has been added to that config file: the IP address, the private key and the public key. Give that file to the wireguard installation on the roadwarrior VPN client, and it'll know what to do.

client config file autogeneration script
========================================

We can make a single script that runs on the server, which generates the client config files for us. Easiest way to control it is to give as input a potential client ip address (and maybe some other server info); the output is tricky, because the client public key has to be added to the server's config. But we can do that - and with the server config modification, output a fresh client config file.

```sh
#!/bin/sh
# client config generation script
# in:  1) client static IP within VPN, 2) server public key
# out: 1) client config file, 2) server wireguard config alteration

clientip="$1"

serverpubkey="asdf9jp2389apfadfasdfasdfa09sf8y23r87h"
serverendpointip='250.123.234.78'
serverportnum='55667'
subnetrange='24'
serverip='10.191.232.1'

# place to put the new client config (the webserver needs to have access here)
mkdir -p     /etc/wireguard/clientconfigs
chmod -R 744 /etc/wireguard/clientconfigs
cd           /etc/wireguard/clientconfigs

# generate the client's private and public keypair, put in variable, delete
wg genkey > "secret.$clientip.key"
wg pubkey < "secret.$clientip.key" > "public.$clientip.key"
privatekey=$(cat "secret.$clientip.key")
publickey=$(cat  "public.$clientip.key")
rm "secret.$clientip.key" "public.$clientip.key"

# create the config file
echo "[Interface]"                                     > "wireguard.$clientip.conf"
echo "Address    = $clientip"                         >> "wireguard.$clientip.conf"
echo "PrivateKey = $privatekey"                       >> "wireguard.$clientip.conf"
echo "ListenPort = $serverportnum"                    >> "wireguard.$clientip.conf"
echo ""                                               >> "wireguard.$clientip.conf"
echo "[Peer]"                                         >> "wireguard.$clientip.conf"
echo "PublicKey  = $serverpubkey"                     >> "wireguard.$clientip.conf"
echo "Endpoint   = $serverendpointip:$serverportnum"  >> "wireguard.$clientip.conf"
echo "AllowedIPs = $serverip/$subnetrange"            >> "wireguard.$clientip.conf"
echo "PersistentKeepalive = 25"                       >> "wireguard.$clientip.conf"

# conclude
echo "new client config generation complete"
echo "file saved to: /etc/wireguard/clientconfigs/wireguard.$clientip.conf"
```

This script doesn't check for old configs for the given IP address, and it only does a single address. But that's ok - we're going to do this on a loop for all desired IP addresses, and we don't really want to keep old configs. Mostly, we want to delete old entries in the server config. But we can make that a separate 'cleanup' script, that runs periodically and compares the current crop of client configs to the `[peers]` in the server config. 

```sh
#!/bin/bash
# cleanup_peers.sh
# run as a root cronjob

while IFS= read -r line; do

  if [[ 'PublicKey' == *"$line"* ]] ; then

    currentconfigversion=False

    pubkey=${line##*=}

    for file in /etc/wireguard/clientconfigs/wireguard.*.conf ; do

      if grep -q -wi "$pubkey" "$file"; then

        currentconfigversion=True
        break

      fi

    done

    if ! [[ "$currentconfigversion" == 'True' ]] ; then

      echo "removing old peer entry! pubkey = $pubkey"
      wg set wg0 peer "$pubkey" remove

    fi

  fi

done < /etc/wireguard/wg0.conf
```