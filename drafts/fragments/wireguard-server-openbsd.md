So this is going to be interesting. Looks like wireguard is awesome, but I have to preassign the IP addresses of the 'clients' - no DHCP equivalent here. Since I'm looking at 20+ clients (windows machines), and not all predictable, it's not super practical to do that per-machine. 

Instead of doing fancy networking that is (so far) way beyond me, or using one of the bigger pieces of software built on top -- which, actually, don't seem to be particularly suited to what I need -- I'm just going to work with what's there, and optimize the availablilty of the given mechanisms and information.  I even looked at the wireguard interface built into OPNSense - and it's still more annoying than the variation I'm trying to do here. 

Bear in mind, my threat model is very not-normal. I'm putting the vpn credentials on an unsecured website on the hardline network, and that's considered preferable to any greater security. It's basically security by obscurity; as long as someone has to physically show up at the building and plug into the network, that's enough of a barrier. 

I could make all this part of the main gateway. However, I think it may pay off to keep it independent. If the only dependencies is the relevant subnet, then this might be more reliable this way. Less likely to die with the rest of the system. Also I feel better about using OpenBSD as the vpn server. 

source: [Creating a Wireguard VPN on OpenBSD](https://xosc.org/wireguard.html)

easy deployment
----------------

Auto-generate 250 keypairs & ip addresses. Make tidy little packages of each, make linux and windows versions (if applicable), make qr code images for each one, and name each package with its associated IP address.  The server will have a big wireguard config file that associates keys with IP addresses. 

Put these in a share drive, and on a little website that lets you download one of your choosing.

The VPN server should log the actual IP addresses that get used. As IP addresses 'go live', because someone fired up their machine with the VPN, append that IP address to the log. Also include the hostname and the MAC address and a fingerprint (basically an nmap scan) so that I can physically locate that machine in the future. 

Now make a lightweight, static, html website. Just one big table: 

ip address | 'datetime last seen' / dead | package download link | # times downloaded | hostname | mac address | [delete&regenerate]

The last seen could link to a page that lists out each day / hour the machine was online. Maybe even graph it? Could easily be done in the background. 'number of times downloaded' helps the sysadmin track which ones have been used. Not so useful as the rest. the delete and regenerate button lets me clear old VPN credentials, so that users are booted and a new packet is created. be sure to save the old packets? 

(green-orange-red color code for datetime last seen - algorithmic, continuous, based on # of days? fun feature creep)

use case
--------

This allows me to visit that website, grab a fresh package, and install it. I can check for unused packages and reuse them. If I want to boot a user, there's a button for it.

Basically, makes the best of statically-assigned IP addresses.

TODO
====

- install wireguard 'server' on openbsd
- all relevant wireguard/openbsd/nat/gateway/etc configs

- generation script: given an IP address & wg config file path (default set); generate keys, add info to (given) wireguard config file, zip it up & name with the ip address.
- 

- lighthttpd website (separate vm, on the hypervisor?)
- put packages in share folder, linked to in the website

- program to generate html page of the website
  * for each IP address in the given range:
    * parse logs to see if IP address is active yet
      * date/time last seen
      * any other log info available?
    * generate url of config package file
    * ip address
    * button to run generation script and also backup the previous version

commands
========

Remember that you'll need a public IP address. 

set up the openbsd server
-------------------------

I'm assuming it's already been installed. If not, go install it. If you can't figure that out, you're not ready for the rest (sorry).

```Shell
su
fw_update
export PKG_PATH=http://mirrors.mit.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/
pkg_add -u
pkg_add vim htop
```

configure wireguard on the server
---------------------------------

This is more of a hello-world than part of the final config; just making sure the system works.  Remember, we're looking at a 'roadwarrior' setup, where there's a node at a static, known address (the 'server'), and a bunch of nodes with unpredictable addresses which initiate connection to the static-address-node (the 'clients').

Create the 'wireguard interface' on the server. In network-engineering-world, interfaces are like portals to other networks; those networks are defined by the range of possible addresses that something on the network can have; and so an interface into that network will have a unique address within that range. _(There's a whole class of problems and workarounds for when multiple networks, available via different interfaces to a single machine, are using the address ranges that overlap. So yes - if that problem occured to you, it's definitely a legitimate problem.)_ 

That is:

```
+------------+
|            |
|   my       |
|   random   |
|   server   |
|            |
|         +--+-----------------+             192.168.43.1/24
|         | if1: 192.168.43.20 +-----------> ---------------
|         +--+-----------------+             192.168.43.1 <-> 192.168.43.255
|            |
|         +--+-----------------+             192.168.1.1/16
|         | if2: 192.168.213.9 +-----------> ---------------
|         +--+-----------------+             192.168.1.1 <-> 192.168.255.255
|            |
|         +--+-----------------+             10.11.12.1/24
|         | if3: 10.11.12.132  +-----------> ---------------
|         +--------------------+             10.11.12.1 <-> 10.11.12.255
+------------+
```

BTW, did you spot the problem? There's an overlap between the networks accessible through the `if1` and `if2` portals. Notice how _big_ the `if2` network is; it covers the whole range of possible addresses between 192.168.1.1 and 192.168.255.255. Now, what if you want to talk with a machine somewhere at the beginning of that range, say at 192.168.40.220? No problem, packets get through just fine. What about 192.168.43.152? Well, now we have a problem: which network are you trying to reach? Because that address is within the defined range of two networks: the one you can see through the `if2` portal, but also the network you can see through the `if1` portal.

When you first open one of these portals, you have no idea what's on the other side. So you send a sort of 'hello, I'm here, who are you?' signal to anything / everything on the other side. Who responds? Suzie's random laptop hooked into the wifi? How does that laptop know any more about the network than you do? 

It doesn't; not without first learning the network parameters from something else.

That something else is the _DHCP server_. That machine tells the others in the network what addresses are available, and assigns them their own if they ask for it.  

What we're doing here is creating a whole new portal, to a whole new network - even though that new network doesn't exist yet. _(We'll create it later, and do some other freaky magic stuff with it.)_  This particular portal is unusual in that everything that passes through the portal is encrypted, automatically, as it goes through. _(The packets sent through this way pass through that network encrypted, before they leave the network through another portal - and if that portal is attached to the intended recipient machine, it will decrypt the packets automatically as they pass through and out.)

The portal will be called `wg0` instead of `if2` or some such. Remember that bit about encryption? Part of creating the portal is also setting up the private key.

```sh
random_string=$(openssl rand -base64 32)
ifconfig wg0 create wgkey $random_string wgport 443
```

We set the _port_ to be static, and to be 443. 

What's a port, you ask? 

Remember those portals? Well, they aren't just firehoses. The packets travelling through them carry numbers - anything that can be expressed with an unsigned 16-bit integer. If you call that sort of talk greek gibberish, worthy of the βάρβαροι, then let's just say the range is between 1 and 2^16-1. What's 2^16-1? Seriously? 65535. The range is 1-65535. Every packet presents a number between 1-65535, and if it presents the correct, predefined, number, it's let through. What we did above was say that we'll only let packets through the `wg0` portal interface if they present us the port number 443.

Let's see what that command did for us. 

```sh
> ifconfig wg0

wg0: flags=8082<BROADCAST,NOARP,MULTICAST> mtu 1420
        index 6 priority 0 llprio 3
        wgport 443
        wgpubkey 9kIc7SzIoKXTFhWohYdHfOWhQZHQgxTp0MfFhj0cUUk=
        groups: wg
```

**Now do the same thing on the client.** Remember, the two ends aren't actually different from each other in how they behave: it's just that only one end is going to know how to find and initiate contact with the other.

```sh
# [on the client]
random_string=$(openssl rand -base64 32)
ifconfig wg0 create wgkey $random_string wgport 443
```

And check the results. Note the public key is different, because it's the other machine.

```sh
> ifconfig wg0

wg0: flags=8082<BROADCAST,NOARP,MULTICAST> mtu 1420
        index 6 priority 0 llprio 3
        wgport 443
        wgpubkey 1RJHBWzt3sH4GQzljwY+VTNGcPS0PHwaGR6knefhNMw=
        groups: wg
```

Public key...

Right. More gibberish. There's this cool thing called public-key cryptography, where you can _encrypt_ anything you like with a _public key_, and only the person with the _private key_ can _decrypt_ it. It's like someone who has a bunch of padlocks and a single key that unlocks all of them. They pass out the padlocks to anyone who asks, and scatter them on the roadside; someone comes, grabs a padlock, goes home, and uses it to lock a chest. They can't open the chest anymore; but if they send that locked chest to the person with the key, it'll get there safely and it'll be unlocked easily.

What we're doing here is creating key/padlock pairs, one for each of the two machines in our test setup. The random string is that padlock - useful to lock things with.  The key that can unlock things is also a similar-looking random string, but that's kept hidden. We don't even need to see it, since the machines keep a copy for themselves automatically.

Moving on rapidly, we tell the server what IP address ranges it should accept packages from. That is; there must already be some network which both the client machine and the server machine are connected to - that both machines have portals into. What is that network? That's what you need to tell the server machine. We're going to pretend that the badly-made set of networks I used in the example farther up is the environment we're working with, and use it as an example.

Also tell the server the _public key_ of the client - it needs to know what padlocks to use on the stuff it sends.  

```sh
# [on the server]
#                   [the client's public key]                    [the network]
ifconfig wg0 wgpeer 1RJHBWzt3sH4GQzljwY+VTNGcPS0PHwaGR6knefhNMw= 10.11.12.1/24
```

Notice - if we specified a wider range of possible addresses for the network, but still included the network above within that range, it would be legit: the network `10.11.12.1/24` is _within_ the network `10.0.0.0/8`, and therefore using the latter instead of the former would _only broaden_ the permitted ip addresses.

Check the results.

```sh
ifconfig wg0
```

Now, do the same thing - again - on the client side. Client needs to know the proper network, too, and what padlocks to use that the server has the key to open.  However, note that in this case, it's not just the network you need to specify - it's the specific address to send info to. We're specifying that only on this side, because we're setting up what's called a 'roadwarrior' setup - the client moves from place to place, the server stays still; this means the server has no idea how to contact the client, but the client always knows where to find the server. Therefore, the client always initiates the connection. Once initiated, however, the client tells the server where it's currently located - like a kid calling their mom at home.  

```sh
# [on the client]
#                   [the server's public key]                    [the server's location & port]      [send to any ip]
ifconfig wg0 wgpeer 9kIc7SzIoKXTFhWohYdHfOWhQZHQgxTp0MfFhj0cUUk= wgendpoint wgserver.example.com 443 wgaip 0.0.0.0/0
```

Note that we can use an ip address instead of the URL.

Finally, speaking of IP addresses, we have to 



generate the html static page
-----------------------------

```html
<table>
  <tr>
    <td>Cell 1</td>
    <td>Cell 2</td>
    <td>Cell 3</td>
  </tr>
  <tr>
    <td>Cell 4</td>
    <td>Cell 5</td>
    <td>Cell 6</td>
  </tr>
</table>
```

