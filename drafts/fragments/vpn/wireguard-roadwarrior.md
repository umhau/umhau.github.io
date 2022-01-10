We're going to create a VPN system from pieces. 

We're going to build a VPN server on OpenBSD and give it its own public IP address; write a program to generate keypairs and config files, and zip them up; create a local website that tracks the status of each VPN client's IP address; create a standardized client config, and automate it. 

Tall order, but we got this.

sources
-------

https://philipdeljanov.com/posts/2019/03/21/setting-up-a-wireguard-vpn/
https://ianix.com/wireguard/openbsd-howto.html
https://xosc.org/wireguard.html

VPN parameters
--------------

Bits of these are scattered over the systems, so this is where I'm just putting all the choices I've made into a single place.

#### VPN subnet range
    10.191.232.1/24

#### VPN public IP address
    250.123.234.78

#### VPN external port number
    55667

build a VPN server on OpenBSD
-----------------------------

We're using wireguard. Do this section all on the OpenBSD server, which should have at least two ethernet ports, one connected to your ISP's router, and the other to your main network. _(It would be possible to use one machine for the VPN and as the network gatway / firewall / DHCP server / etc, but I'm using OPNSense for that; for the VPN, which hopefully won't have to be touched frequently - or ever - I want OpenBSD. It has an in-kernel wireguard implementation, and its networking configurations are far cleaner, and it should last much longer on its own, if some future sysadmin gets negligent.)_

Wireguard is already installed, in the kernel no less; there's a set of extra tools we can install, so let's do that. And while we're at it, lets get some desprately needed utilities on there.  

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

That's it for telling the OpenBSD machine what we expect from it. Now let's tell it how we want it to run this VPN. This config file is going to hold both the server configs, and the info it keeps on each client - which means, we'll be modifying it regularly and programmatically.

```sh
# check what the private key is
cat /etc/wireguard/secret.key

# edit the config file. you'll need the private key
vim /etc/wireguard/wg0.conf
```

This is the first section of what will be a very long file. 
```sh
# server configs
[Interface]
PrivateKey = <Contents of the server privatekey file>
ListenPort = 51820   
SaveConfig = true    # this lets us permanently add peers to the file via command line
Address = 172.16.0.1/16 
```

We're going to autogenerate the client configs that go in this file, but let's just note below what those client configs will look like.  Note that the allowed IP is only a single address - the IP address of itself, the server, as it presents itself within the network. That is, if the VPN subnet range is 10.191.232.1/24, and the server gives itself the first IP address in the range, then the allowed IP of each peer is simply `10.191.232.1/32`.  Note that this is expressed as a range, but if we use `/32` then it's a range of one.

The public key in the _server's_ config entry for each client/peer is the public key of the _server_, which we just created. (Remember, so far we haven't done anything that touches the clients.)

```sh
[Peer]
PublicKey = BBBB  
AllowedIPs = 10.191.232.1/32
```



