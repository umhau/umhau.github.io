---
layout: post
title: A roadwarrior VPN server setup for a small group
author: umhau
description: "roadwarrior"
tags: 
- wireguard
- OpenBSD
- roadwarrior
- networking
- VPN
- lighttpd
- simple
- ergonomic
categories: walkthroughs
---

**work in progress. easier to read on the blog than in VS code while I'm building it.**

We're going to build a VPN server on OpenBSD and give it its own public IP address; write a program to generate VPN client config files; create a local website that tracks the use/disuse status of each VPN client's IP address; and automate the whole thing so it's autonomous for years at a stretch. 

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
[genclient.sh] given an ip address, creates and inserts a complete client config
[pf.conf]      OpenBSD firewall config; must modify to allow VPN traffic through
[wg0.conf]     Tells wireguard what settings to use for the VPN
```

I don't think I need this one - pretty sure parsing `wg0.conf` is just as effective, and removes synchronization errors.

```
[clients.csv]  list of all current client configs - ip address and private key
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

_(By the way, I'm fully aware that the following method for putting text in a file is...inelegant, to put it mildly. However, I'm writing this post as a prelude to a fully-scripted system, and I want to be able to just copy-paste from this post; and, once inside a very large script, this format is the most-readable method for dumping a lot of text into config files I've been able to come up with. Ironically, the consistent repetition and lack of preamble means it's easy to just ignore the bits of each line that aren't the script contents._

_Tell me it's not awesomely easy to read._

_Oh, wait. There's no comment section. You can't.)_

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
echo "[Interface]"                                    >> "wireguard.$clientip.conf"
echo "Address    = $clientip"                         >> "wireguard.$clientip.conf"
echo "PrivateKey = $privatekey"                       >> "wireguard.$clientip.conf"
echo "ListenPort = $serverportnum"                    >> "wireguard.$clientip.conf"
echo ""                                               >> "wireguard.$clientip.conf"
echo "[Peer]"                                         >> "wireguard.$clientip.conf"
echo "PublicKey  = $serverpubkey"                     >> "wireguard.$clientip.conf"
echo "Endpoint   = $serverendpointip:$serverportnum"  >> "wireguard.$clientip.conf"
echo "AllowedIPs = $serverip/$subnetrange"            >> "wireguard.$clientip.conf"
echo "PersistentKeepalive = 25"                       >> "wireguard.$clientip.conf"
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

This script doesn't check for old configs for the given IP address, and it only does a single address. But that's ok - we're going to do this on a loop for all desired IP addresses, and we don't really want to keep old configs. Mostly, we want to delete old entries in the server config. Otherwise you could steal an old config and still get into the server. But we can make that a separate 'cleanup' script, that runs periodically and compares the current crop of client configs to the `[peers]` in the server config. 

In terms of security, this setup means that if someone steals an old config file, they have exactly `N` minutes to use it before the cleanup script nukes the keys it uses - where `N` is the period at which you run your cronjob. Just how paranoid are you? Would you give an attacker a whole 24 hours to use that key, or would you rather give them a max of just 10 minutes?

```sh
chmod +x /etc/wireguard/cleanup_peers.sh
crontab -e
30 * * * * /etc/wireguard/cleanup_peers.sh
```

_(Just make sure you don't make `N` shorter than the time it takes for the script to run. Maybe do it a few times on your system to time it, then double or triple that time and consider that the minumum `N` your system can handle. The script below definitely isn't fast - if you have 255 IP addresses in the range, then it's going to do something like 32640 file reads at best, more if there's keys to remove.)_

```sh
#!/bin/ksh
# cleanup_peers.sh
# run as a root cronjob

# we need a place to put backups of the server config
mkdir -p /etc/wireguard/backups

# initialize the list of old-public-keys-that-need-to-be-removed
badpeers=''

# read the server config file line-by-line
while IFS= read -r line; do

  # see if the current line contains a public key that we want to check
  if [[ 'PublicKey' == *"$line"* ]] ; then

    # that public key is NOT considered up-to-date for that IP address, *until proven otherwise*
    currentconfigversion=False

    # extract the key, by itself, from the rest of that line and clean it up
    pubkey=$(echo ${line##*PublicKey = } | xargs)

    # search the client config directory for any available match
    if grep -qr "$pubkey" /etc/wireguard/clientconfigs/wireguard.*.conf ; then

      # then the public key we have is, indeed, the up-to-date current key
      currentconfigversion=True

    fi

    # if we never found a config file with the public key
    if ! [[ "$currentconfigversion" == 'True' ]] ; then

      # then this is an out-of-date key, and should be added to the list for removal
      badpeers="${badpeers} $pubkey"

    fi

  fi

done < /etc/wireguard/wg0.conf

# if our list of keys-to-remove has anything in it
if [ ! -z $badpeers ] ; then

  # first backup the server config - this helps recover from butterfingers
  cp /etc/wireguard/wg0.conf /etc/wireguard/backups/wg0.$(date +"%s").conf

  # go key-by-key through our list of keys-to-remove
  for badpeer in $badpeers ; do

    # and remove the entire peer entry corresponding to that key
    wg set wg0 peer "$badpeer" remove
  
  done

fi

# remove the old client configs

# # iterate over each client config file
# for file in /etc/wireguard/clientconfigs/wireguard.*.conf ; do

#   # extract the line containing the public key
#   pubkey=$(grep 'PublicKey' $file | cut -f 3 -d '==' | xargs)
#   echo ${pubkey##*PublicKey = }

#   # see if the server config DOESN'T contain the public key of this client config
#   if ! grep -q -wi "$pubkey" "/etc/wireguard/wg0.conf"; then

#     # if it doesn't, the client config is out of date and should be removed
#     cp $file /etc/wireguard/backups/$(basename $file).$(date +"%s")

```


track the use of each IP address / pubkey set
=============================================

This is going to be used by the website, but we can write it as a script to get the benefit on the command line, too.  We just want to know if a specific client config file, uniquely identifiable by either its public key or IP address, has been added to someone's machine. Actually, we can't know _that_ specifically, but we can figure out if it's been added to someone's machine _and the machine has connected the VPN to the network_.

_(we can also track if the config's been downloaded, and even reset that counter each time we reset that config file, but that's a different script for a later time.)_ 

Should be able to simply parse the pf log after enabling logging; however, I don't know how much that slows the system down.

https://www.openbsd.org/faq/pf/logging.html


autogenerate an html file describing the state of each client
=============================================================

Since the IP addresses for the VPN clients have to be static, that introduces a host of complications - I can't just hand out keys and keep the range big enough for the current set of users, because old users won't give up their assigned IP addresses, and I'll run out. So I need an easy way to see which addresses are free, and which are used, and which haven't been used in a long time, and to generate new keys for old addresses when I want to revoke someone's access.  That's what this little site is for, and the fun thing is, it can be totally static.

<!-- Security by obscurity at its finest. And if that doesn't work, we can keep the first 10 or so ip addresses reserved so that the interface can't mess with them. That way some kid who wanders in and finds the site won't knock the admins off the VPN, and it'll at least be recoverable.  Or I could make the site password-protected.  -->

We want an HTML table with one row per ip address, and a column dedicated to each available piece of information about that ip address - public key, date last seen, download button, reset button, etc. 

To generate this table, we'll iterate over the client config files, pull the info, and write the html file line-by-line. First, let's make sure we can grab the info we need.

```sh
#!/bin/sh

sitefile='/etc/wireguard/index.html'

echo '<html><head></head><body><table>' > "$sitefile"

for file in /etc/wireguard/clientconfigs/wireguard.*.conf ; do

  ipaddr=$(grep 'Address' $file)   ; ipaddr=$( echo ${pubkey##*Address = }   | xargs)
  pubkey=$(grep 'PublicKey' $file) ; pubkey=$( echo ${pubkey##*PublicKey = } | xargs)

  downloadbutton="<a href=\"$file\" download=\"$(basename $file)\">$(basename $file)</a>"
  resetbutton="<form action=\"\" method=\"post\"> <input type=\"submit\" name=\"$ipaddr\" value=\"$(echo $ipaddr | sed 's/\.//g')\" /> </form>"

  # force download of a file (HTML5)
  # <a href="./directory/yourfile.pdf" download="newfilename">Download the pdf</a>

  # reset button general format
  # <form action="" method="post">
  #     <input type="submit" name="upvote" value="Upvote" />
  # </form>

  # generate the html!

  echo "<tr> <td> $ipaddr </td> <td> $downloadbutton </td> <td> $pubkey  </td> <td> $resetbutton </td> </tr>" >> "$sitefile"

# <table>
#   <tr> <td>Cell 1</td> <td>Cell 2</td> <td>Cell 3</td> <td>Cell 3</td> </tr>

#   <tr> <td>Cell 4</td> <td>Cell 5</td> <td>Cell 6</td> </tr>
# </table>

done

echo '</table></body></html>' >> "$sitefile"

```

install a webserver to host the internal website
================================================

Can't have a website without a webserver.  Install it. OpenBSD will ask you which version to install; pretty sure we don't need a database for this (that's what ldap and mysql are), so just go with option 1.

```sh
pkg_add lighttpd
```

The lighttpd config file is located at 
```
/etc/lighttpd.conf
```


