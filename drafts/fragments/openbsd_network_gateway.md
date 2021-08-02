# OpenBSD Router

One of my clients has a PFSense box and Active Directory box on-premise. I'd like to recombine their functions into an OpenBSD box for networking, and a Samba box (or two) for AD user authentication and the fileserver. This post covers the process of building the OpenBSD box. Additionally, I'm building a very similiar OpenBSD box for my personal network; given the similarity, I'll start the process identically, and comment on the divergence later, as a couple of addendums / diffs. 

I remain blown away by the quality of the OpenBSD documentation. Given just how amazingly good it is, I'm going to quote extensively from the online documentation pages - this post may turn out to be an edited, annotated collection from those docs. Usually my posts require a lot more work than that, but these guys know how to write. Kudos.

As it turns out, most of the comments and additions I'm making are definitions and explanations - I'm working off of the 'how to build a router' [page](https://www.openbsd.org/faq/pf/example1.html), but didn't know a lot of the terminology and concepts. So after a brief stint reading (nearly) all the `PF` docs, I'm back - and ready to write this post with a lower assumption of prior knowledge.

## Introduction

This device we propose to build sits between your home network and the rest of the internet. It's a _router_: what's usually, in a home environment, a wifi router installed by the internet company. This thing creates the local subnet, manages DHCP queries, and (hopefully) runs a firewall of some kind. I say this, not to impune your intelligence, but to estabilsh clearly that that is, indeed, the sort of device we're talking about here. 

Sometimes we (I...) can get into the weeds so far -- trying to fix a 10-years-out-of-date PFSense box, or using fancy labels like 'internet gateway' -- that we forget just how simple the thing really is that we're trying to fix.  All the VPN configs, firewall madness, and DHCP server forwarding and duplication just obscures the simple fact that this is a _router_, and is fundamentally the same sort of box as that cheap thing sitting in your closet at home.  

As such, there's some things that we want to set up and / or configure.  Some are fundamental, some are just icing, and some are just settings to set.

### Useful links: 

- [Installing OpenBSD](https://umhau.github.io/setting-up-openbsd/)
- [Building an OpenBSD router](https://www.openbsd.org/faq/pf/example1.html)
- [openbsd networking](https://www.openbsd.org/faq/faq6.html)

### Fundamental: 

- [ ] **Network Address Translation** ([NAT](https://www.openbsd.org/faq/pf/nat.html)). This is another way of saying that since the Internet Service Provider (ISP) generally gives out a limited number of IP addresses, we have the _router_ create a subnet for the local devices to use. This is why we have an 'external' IP address, and an 'internal' IP address: all the devices share that external IP address, which could be anything: `143.15.27.189`, for instance, while the local network usually gives you an IP address that looks something like: `192.168.1.*`. 

Not everything is just software: in order for this new OpenBSD box to function as intended, there actually have to be two cables attached: one for the connection to the outside world, one for the connection to the smaller world inside. The 'outside world', in this case, is called the Wide Area Network (WAN), and the 'smaller inside world' with the local subnet is called the Local Area Network (LAN).  If you've heard of these terms before, now you know where they come from.

As a side effect of this process, a server sitting somewhere else in the Internet will only ever see the 'external' IP address. Put another way, this setup makes the OpenBSD box, the router, funnel all the traffice to and from the outside world through itself.  This makes it look, to that server outside the local network, like all the internet traffic from the devices inside the Local Area Network is actually coming from the OpenBSD router. [Source](https://www.openbsd.org/faq/pf/nat.html)

- [ ] **IP Forwarding**. This allows packets to travel between network interfaces on the OpenBSD machine.  It's a single line added to a config file, but it's crucial enough to warrant mention.

- [ ] **DHCP server**. Within the local network, devices still need IP addresses. This process on the OpenBSD machine hands out those address on-request. Note, there is an additional service this can perform: IP address reservations based on MAC address. This means that if I know the MAC address for a specific device, I can give it a predetermined IP address. (I'm pretty sure this also means I can assign devices to specific subnets, based on their MAC address range - since MAC addresses are often assigned in lumps to manufacturers, this means I can, e.g., put a bunch of fancy internet-connected phones all on the same subnet just by knowing what MAC address range their manufacturer was assigned.)

- [ ] **Firewall**. This is, honestly, just a big catch-all for 'rules to choose which packets get sent where'.  One of the most important types of rules, however, is 'block packets to and from hostile sources', so that's where the name comes from. The tool used to manage the firewall is `PF` (Packet Filter), so that's appropriately generic, at least. 

If you don't set this up, your router probably won't work, and you'll probably have a very bad time. 

Part of the firewall is [Port Forwarding](https://www.openbsd.org/faq/pf/rdr.html), which lets me do things like host a public website from a server inside the local network, or ssh into one of my machines when I'm not at home (possibly using a 'jump server', though I only heard of that term after I called mine a 'pivot server').

### Icing (additional settings & functions)

- [ ] **DNS caching**. The 'natural' way to connect to another server, on the local network or on the wider internet, is through IP addresses like `192.168.1.23` (a local device), or `80.82.77.84` (a device/server on the WAN).  

However, strings of numbers are hard to remember, and words and phrases are easier. This is why we use URLs, like `umhau.github.io`.  However, a URL is like sending someone a postcard by writing their name, but leaving off their street address: it works, but only if the post office knows what address goes with their name (the analogy only works if everyone in the world has a unique name).  So, in order for URLs to work, we set up servers that keep lists of which URLs correspond to which IP addresses, and then tell our computers to go to those servers to ask what IP address is associated with `umhau.github.io`.  These are called Domain Name System (DNS) servers, and we have to explicitly tell our computers which _DNS Servers_ they should use. 

There's some common servers, like `8.8.8.8` and `1.1.1.1`, which are hosted by Google and Cloudflare.  These are useful public services, though they're probably also extremely useful as a source of information: if you use `8.8.8.8` to figure out how to connect to each website you want to visit, then you've just told Google about your complete browsing history.  

This is all just introduction. The point is, it's inefficient and slow to send queries across the internet every time you want to visit a website. This line item in the OpenBSD configuration list is for DNS caching - which means that recent queries are stored by your router, so that if two devices both try to access `facebook.com` in a short period of time, the router will remember what was looked up by the first device, and will just send the same response to the second device. Makes things quicker, though if the IP address changes in the meantime, the cache won't update until the router thinks it's time to double-check the data.

- [ ] **Virtual Private Network** (VPN). This is going to be complicated, and definitely will merit its own post.  I'm not totally sure how to set this up, but there's some distinct pieces to it.  I want to create a virtual device, and have a wired subnet that funnels all it's data transparently throught the VPN.  That way I don't have to install the VPN software on my machines. 

I also want to set up a VPN-based LAN that I can share with my friends - a sort of darknet. 

Finally, I want to be able to connect to my home network remotely, and I wonder if a VPN is the best way to do that. However, that would mean disabling the VPN while those devices are on the home network, since otherwise there would be strange loops.

## Initial System Configuration

### Hardware Arrangement

[Hardware requirements.](https://www.openbsd.org/faq/pf/perf.html)

This is a standalone physical device with ~4 network ports and 1+ usb wifi cards attached. Internally, there's [not a lot of difference](https://www.openbsd.org/faq/faq6.html#Wireless) between the usb wifi and the built-in ethernet ports: the `/etc/hostname.<device>` for wifi gets a couple extra lines for wifi name and password, and that seems to be about it.  

Just make sure the firmware is installed.

	fw_update
	
This can't be done without an internet connection, but will make sure that if the wifi card firmware is officially supported, it is installed without issue. [Supported wifi cards](https://www.openbsd.org/faq/faq6.html#Wireless).

### package installation

Make sure we can install packages. You only need one of the following two lines; use whichever works better.

    export PKG_PATH=http://mirrors.mit.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/
    export PKG_PATH=https://plug-mirror.rcac.purdue.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/

Now we can install a package with

    pkg_add nano

Remove previously-installed packages with

    pkg_delete nano

Search for packages by name with

    pkg_info -Q nano







### network devices

_I don't think this section is needed._

Both ethernet connections should be active.  I think I may have used `ifconfig xnf1 up` to activate the secondary interface, but I'm not sure...too many false starts, too many different things getting built. The below refers to a virtual network device, hosted by xen.  Use `ifconfig` to figure out what network devices are available to you.  If you're missing one that you expected to see, the firmware might not be installed (see above).

    echo dhcp > /etc/hostname.xnf1

To apply changes, use:

	sh /etc/netstart


## Router Setup

### Network Definition

First, let's outline how I'm setting up my local network. This router is going to be accessing the outside internet through a wireless connection - remember how I mentioned that your wifi card might need firmware, that has to be downloaded from online? Yeah...that was fun.  

I'm also going to have at least two local subnets, though one of those three is going to come later: an 'insecure' subnet, that I use for gaming, video calls, and random software that won't function without strange workarounds; and a 'secure' network, that has packet filtering implemented and maybe even a transparent VPN. I'm still not sure about the division between the subnets, and I might end up wanting more - my router has 4+1 ethernet ports, so I can definitely do it - but I lose the transparency to the connected devices if I have to connect multiple cables to them. 

That's the thing: while [it's possible](https://man.openbsd.org/dhcpd.conf#REFERENCE:_DECLARATIONS) to have multiple subnets on the same physical wire, and just segregate based on MAC address, requested static IPs, fingerprinted OSes, and a default association, the best-practice is to use separate physical networks (hence the use of separate physical ethernet ports on the OpenBSD router).  This, in turn, necessitates buying and pulling multiple sets of cables, and tracking which cables are connected to which subnets (yay for colored cables).  This is feasible, but better to buy and pull two sets of cables than four or five.

Note that I would use network switches to connect the devices together: one switch for each subnet, and the OpenBSD router would be connected to each of the subnets via the specific hardware port associated with that subnet. 

All that filtering can be disruptive, if not done right, but I'd like to avoid infinite gradations of security settings on their own subnets. And thus we reach yet another classic tradeoff.  My solution is to do two for a start, 'secure' and 'insecure' and just see what's practical for each.

Thus, two local subnets. I have ethernet devices labeled `em0` through `em3`, and an `athn0` usb Wifi device.

	em0 [secure]   10.0.0.1/24
	em1 [insecure] 10.0.1.1/24
	
Each of these subnets give us 255+1 available IP addresses to work with.  I doubt my personal network will need more than that. (BTW, because it would have confused me when I was younger: the 0 in `em0` has nothing to do with the 0 in `10.0.0.1/24`, except that I liked the symmetry. Could just as easily have been `10.0.231.1/24`, or a wide variety of other ranges.)

I haven't yet decided how to set up the wifi. I have an old router that I could put into bridging mode and connect to one of the physical networks; that would certainly work, but it feels less put-together than another usb wifi device.  We'll see. 

Enable packet forwarding between network devices. This is what officially tells the machine that it's not just another device on the network, but is actually routing packets around. 

    echo 'net.inet.ip.forwarding=1' >> /etc/sysctl.conf

Set up the device that manages incoming traffic, that's connected to the external network. This is the 'WAN' device, since it's connected to the WAN.  

In my case, this is a wifi device, so it needs wifi information. I'm not using a static IP address, so I just tell it to use `dhcp` to negotiate whatever address the upstream router decides to give it.  I think, if this were truly the box connected directly to the outside Internet, I would need to ask my ISP what my IP address is and set that as static (or maybe the ISP runs a DHCP server that negotiates that automatically? I don't know).

You'll need to figure out what OpenBSD calls the wifi device. Mine is called `athn0`, because it uses the Atheros driver. Run `ifconfig` to figure out what yours is called. 

Put the following into `/etc/hostname.<device>` (since mine is `athn0`, I put the following into `/etc/hostname.athn0`.  

    nwid '<wifi network name / SSID>'
    wpakey '<wifi password>'
	dhcp

That's the incoming connection. Since I want [two different subnets](https://man.openbsd.org/hostname.if), that means I have two outgoing connections: one to the 'secure' network, and one to the 'insecure' network.

    echo 'inet 10.0.0.1 255.255.255.0 10.0.0.255 description   "secure network"' > /etc/hostname.em0
	echo 'inet 10.0.1.1 255.255.255.0 10.0.1.255 description "insecure network"' > /etc/hostname.em1

BTW, I'm pretty sure there's a typo in the OpenBSD [doc](https://www.openbsd.org/faq/pf/example1.html#net). For the wifi config, it only says we need to specify `inet 192.168.2.1 255.255.255.0`, and left out the final `182.168.2.255`.  

...pretty sure. yeah.

### Dynamic Host Configuration Protocol (DHCP)

That's a really fancy way of saying 'this is the program that gives devices IP addresses'.  Since we're building a router, that's this baby.

First, enable the daemon (what's a daemon? See [here](https://en.wikipedia.org/wiki/Daemon).  Wait, no, see [here](https://en.wikipedia.org/wiki/Demon_(thought_experiment)). Nope, [this is it](https://en.wikipedia.org/wiki/Daemon_(computing)#Terminology).). 

    rcctl enable dhcpd
	
However, where should the router provide the DHCP service? Should it give out IP addresses to the whole Internet, over the `athn0` connection? We need to tell it where to operate. We want it to give out IP addresses on the `secure network` and the `insecure network`. We can tell it this using the associated ethernet ports:

    rcctl set dhcpd flags em0 em1
	
Now, when a device sends DHCP IP address request packets that bubble up through the `em0` or `em1` ethernet ports, the OpenBSD router will know to go ahead and answer them with a free (free as in available) IP address they can use.

Finally, even though the DHCP server knows to answer packets on those two devices, it doesn't actually know what to say: what address ranges to hand out. Should it give out `192.168.1.5`? How about `10.10.10.123`? And what should it say, when the device on the subnet wants to know the IP address of the OpenBSD router itself?  We edit the file `/etc/dhcpd.conf` to hash this out.

	option domain-name "example.org";
	
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

Notice that the OpenBSD router will be available by different IP addresses to devices on each subnet: to the 'secure network' devices it is has the IP address `10.0.0.1`, and to the 'insecure network' devices it has the IP address `10.0.1.1`; on the larger network, it has whatever address it got through DHCP. 

Also note there are other options here: if you set up a domain name for the whole network (instead of separate domain names for each of the subnets, then put the option at the top, outside the subnet specifications.



### Firewall

Finally! The part we've all been waiting for. Previously, we've described the paths, along which 'data' may flow; now we get to say what data can go where. We generally talk about the 'data' as _packets_, which have _headers_ and _bodies_.  

    [ header ] [ body ]
	
The headers contain information like 'where the data is going' and 'where it came from' and 'what sort of data it is'.  Sometimes there may be several layers to the header, and sometimes the body itself may be multiple packets stored together.  Things get more complicated when some of the parts are encrypted, or the body is itself an encrypted packet. It's all very confusing, but there's a definite logic to it: just a lot of possibilities.

So. We need to decide how to sort these packets, as they pass through the router. Remember, a packet can only be sorted / filtered by the router _if it passes through the router_.  Sometimes it won't, when you might think it would.

All our firewall configurations and alterations go in `/etc/pf.conf`, and are managed by...`PF`.  We're going to be dealing with three devices, so we'll enumerate them at the top of the file, with variables in case we change the ports.

    secure   = "em0"
    insecure = "em1"

Instead of setting a similar variable for the device connected to the outside internet, there's a [group name](https://man.openbsd.org/ifconfig#group) that covers the [egress point](https://www.thefreedictionary.com/egress) of the local network: `egress`. 

>  In this case, the egress group is being used rather than a specific interface name. By doing so, the interface holding the default route (em0) will be chosen automatically. [src](https://www.openbsd.org/faq/pf/example1.html#pf)

Note that we're using `athn0` as the egress point, rather than the `em0` mentioned in the quotation.

	table <martians> { 0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16     \
			   172.16.0.0/12 192.0.0.0/24 192.0.2.0/24 224.0.0.0/3 \
			   192.168.0.0/16 198.18.0.0/15 198.51.100.0/24        \
			   203.0.113.0/24 }

This is a table of IP addresses that should not be available outside the local network. If a packet tries to get in through the egress point and provides one of these IP addresses as a source or destination address, it is certainly either malicious or badly made.  But more on that later. 

Now we're going to set some PF [options](https://www.openbsd.org/faq/pf/options.html).

	set block-policy drop
	
If we block a package, we will not send a return message saying that we blocked it; we'll just silently drop it.  

	set loginterface egress
	
We're going to collect some logging information on the interface(s) that are considered egress points (and considered so because the system automatically put them inside the egress group).

	set skip on lo0
	
The loopback device (`lo0`) is a virtual device that doesn't have an traffic...so we're going to just not do anything with it, and skip it.

> Skip all PF processing on interface. This can be useful on loopback interfaces where filtering, normalization, queueing, etc, are not required. This option can be used multiple times. By default, this option is not set. 





## PF runtime options

These are the options that I figure are worth using. See [here](https://www.openbsd.org/faq/pf/options.html) for the rest. 

    set skip on interface

Skip all PF processing on `interface`. This can be useful on loopback interfaces where filtering, normalization, queueing, etc, are not required. This option can be used multiple times. By default, this option is not set. 

    set optimization option

Optimize PF for one of the following network environments:

- `normal` - suitable for almost all networks.
- `high-latency` - high latency networks such as satellite connections.
- `aggressive` - aggressively expires connections from the state table. This can greatly reduce the memory requirements on a busy firewall at the risk of dropping idle connections early.
- `conservative` - extremely conservative settings. This avoids dropping idle connections at the expense of greater memory utilization and slightly increased processor utilization. 

The default is normal. 

## PF config

The [pf(4)](https://man.openbsd.org/pf.conf) packet filter modifies, drops, or passes packets according to rules or definitions specified in pf.conf.

Each packet is evaluated against the filter ruleset from top to bottom. By default, the packet is marked for passage, which can be changed by any rule, and could be changed back and forth several times before the end of the filter rules. **The last matching rule wins,** but [there is one exception](https://www.openbsd.org/faq/pf/filter.html#quick) to this: The `quick` option on a filtering rule has the effect of canceling any further rule processing and causes the specified action to be taken.



### Examples

Allow ssh connections in on the external interface as long as they're NOT destined for the firewall (i.e., they're destined for a machine on the local network). log the initial packet so that we can later tell who is trying to connect. Uncomment last part to use the tcp syn proxy to proxy the connection.

    pass in log on egress proto tcp to ! <firewall> port ssh # synproxy state


The recommended practice when setting up a firewall is to take a "default deny" approach. That is to deny everything and then selectively allow certain traffic through the firewall. This approach is recommended because it errs on the side of caution and also makes writing a ruleset easier.  To create a default deny filter policy, the first filter rule should be:

    block all

This will block all traffic on all interfaces in either direction from anywhere to anywhere. 



### DNS Resolution

Make sure to put a proper [nameserver](https://en.wikipedia.org/wiki/Name_server) in the `/etc/resolv.conf` [file](https://man.openbsd.org/resolv.conf).  E.g., `8.8.8.8`, which is the Google DNS server. 

    search example.org
    nameserver 8.8.8.8

# Security Considerations and Mechanisms

The recommended practice when setting up a firewall is to take a "default deny" approach. That is to deny everything and then selectively allow certain traffic through the firewall. This approach is recommended because it errs on the side of caution and also makes writing a ruleset easier. 

Whenever traffic is permitted to pass through the firewall, the rule(s) should be written to be as restrictive as possible. This is to ensure that the intended traffic, and only the intended traffic, is permitted to pass.

## Port forwarding

See the section "Security Implications" [here](https://www.openbsd.org/faq/pf/rdr.html).

Redirection does have security implications. Punching a hole in the firewall to allow traffic into the internal, protected network potentially opens up the internal machine to compromise. If traffic is forwarded to an internal web server and a vulnerability is discovered in the web server daemon, that machine can be compromised by an intruder on the internet. From there, the intruder has a doorway to the internal network: one that is permitted to pass right through the firewall.

These risks can be minimized by keeping the externally accessed system tightly confined on a separate network. This network is often referred to as a **demilitarized zone (DMZ)** or a private service network (PSN). This way, if the web server is compromised, the effects can be limited to the DMZ/PSN network by careful filtering of the traffic permitted to and from them. 

## Blocking spoofed packets

Address spoofing is when a malicious user fakes the source IP address in transmitted packets in order to either hide the real address or to impersonate another node on the network. Once the address has been spoofed, a network attack can be launched without revealing the true source of the attack. An attacker can also attempt to gain access to network services that are restricted to certain IP addresses.  PF offers some protection against address spoofing through the antispoof keyword:

    antispoof [log] [quick] for interface [af]

Where, 

- `log` Specifies that matching packets should be logged via [pflogd(8)](https://man.openbsd.org/pflogd).
- `quick` If a packet matches this rule then it will be considered the "winning" rule and ruleset evaluation will stop.
- `interface` The network interface to activate spoofing protection on. This can also be a list of interfaces.
- `af` The address family to activate spoofing protection for, either inet for IPv4 or inet6 for IPv6. 

For example:

    antispoof for fxp0 inet



# For Future Consideration

(Advanced stuff that I don't think I need right now.)

## Anchors

 In addition to the main ruleset, PF can also evaluate sub-rulesets. Since sub-rulesets can be manipulated on the fly by using pfctl(8), they provide a convenient way of dynamically altering an active ruleset. Whereas a table is used to hold a dynamic list of addresses, a sub-ruleset is used to hold a dynamic set of rules. A sub-ruleset is attached to the main ruleset by using an anchor. 

