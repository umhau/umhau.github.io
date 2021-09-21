---
layout: post
title: OpenBSD Router
author: umhau
description: "from start to finish"
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

This post covers the process of building an OpenBSD router box. 

I remain blown away by the quality of the OpenBSD documentation. Given just how amazingly good it is, I'm basically just going through their documentation and rewriting it into something far more verbose, but which makes sense to me, and uses fewer assumptions of knowledge. I had to do a lot of back-and-forth to look up definitions and explanations (wikipedia FTW), so I'm including those definitions and explanations inline, restated in my own words (best way to learn...is to teach. I feel for the poor sods reading this atrocity. "If I had more time, I would have made it shorter.").   

I'm working off of the 'how to build a router' [page](https://www.openbsd.org/faq/pf/example1.html), but didn't know a lot of the terminology and concepts. So after a brief stint reading (nearly) all the `PF` docs, I'm back - and ready to write this post with a lower assumption of prior knowledge.

After the extreme length of this post, I'll follow up with a shorter one that just sticks with the basics - I think the how to build a router page the openbsd folks put out isn't quite what it needs to be.

# Introduction

This device we propose to build sits between your home network and the rest of the internet. It's a _router_: what's usually, in a home environment, a wifi router installed by the internet company. This thing creates the local subnet, manages DHCP queries, and (hopefully) runs a firewall of some kind. I say this, not to impune your intelligence, but to estabilsh clearly that that is, indeed, the sort of device we're talking about here. 

Sometimes we (I...) can get into the weeds so far -- trying to fix a 10-years-out-of-date PFSense box, or using fancy labels like 'internet gateway' -- that we forget just how simple the thing really is that we're trying to fix.  All the VPN configs, firewall madness, and DHCP server forwarding and duplication just obscures the simple fact that this is a _router_, and is fundamentally the same sort of box as that cheap thing sitting in your closet at home.  

As such, there's some things that we want to set up and / or configure.  Some are fundamental, some are just icing, and some are just settings to set.

## Useful links: 

- [Installing OpenBSD](https://umhau.github.io/setting-up-openbsd/)
- [Building an OpenBSD router](https://www.openbsd.org/faq/pf/example1.html)
- [openbsd networking](https://www.openbsd.org/faq/faq6.html)

## Fundamental: 

[ ] **Network Address Translation** ([NAT](https://www.openbsd.org/faq/pf/nat.html)). This is another way of saying that since the Internet Service Provider (ISP) generally gives out a limited number of IP addresses, we have the _router_ create a subnet for the local devices to use. This is why we have an 'external' IP address, and an 'internal' IP address: all the devices share that external IP address, which could be anything: `143.15.27.189`, for instance, while the local network usually gives you an IP address that looks something like: `192.168.1.*`. 

Not everything is just software: in order for this new OpenBSD box to function as intended, there actually have to be two cables attached: one for the connection to the outside world, one for the connection to the smaller world inside. The 'outside world', in this case, is called the Wide Area Network (WAN), and the 'smaller inside world' with the local subnet is called the Local Area Network (LAN).  If you've heard of these terms before, now you know where they come from.

As a side effect of this process, a server sitting somewhere else in the Internet will only ever see the 'external' IP address. Put another way, this setup makes the OpenBSD box, the router, funnel all the traffice to and from the outside world through itself.  This makes it look, to that server outside the local network, like all the internet traffic from the devices inside the Local Area Network is actually coming from the OpenBSD router. [Source](https://www.openbsd.org/faq/pf/nat.html)

- [ ] **IP Forwarding**. This allows packets to travel between network interfaces on the OpenBSD machine.  It's a single line added to a config file, but it's crucial enough to warrant mention.

- [ ] **DHCP server**. Within the local network, devices still need IP addresses. This process on the OpenBSD machine hands out those address on-request. Note, there is an additional service this can perform: IP address reservations based on MAC address. This means that if I know the MAC address for a specific device, I can give it a predetermined IP address. (I'm pretty sure this also means I can assign devices to specific subnets, based on their MAC address range - since MAC addresses are often assigned in lumps to manufacturers, this means I can, e.g., put a bunch of fancy internet-connected phones all on the same subnet just by knowing what MAC address range their manufacturer was assigned.)

- [ ] **Firewall**. This is, honestly, just a big catch-all for 'rules to choose which packets get sent where'.  One of the most important types of rules, however, is 'block packets to and from hostile sources', so that's where the name comes from. The tool used to manage the firewall is `PF` (Packet Filter), so that's appropriately generic, at least. 

If you don't set this up, your router probably won't work, and you'll probably have a very bad time. 

Part of the firewall is [Port Forwarding](https://www.openbsd.org/faq/pf/rdr.html), which lets me do things like host a public website from a server inside the local network, or ssh into one of my machines when I'm not at home (possibly using a 'jump server', though I only heard of that term after I called mine a 'pivot server').

## Icing (additional settings & functions)

- [ ] **DNS caching**. The 'natural' way to connect to another server, on the local network or on the wider internet, is through IP addresses like `192.168.1.23` (a local device), or `80.82.77.84` (a device/server on the WAN).  

However, strings of numbers are hard to remember, and words and phrases are easier. This is why we use URLs, like `umhau.github.io`.  However, a URL is like sending someone a postcard by writing their name, but leaving off their street address: it works, but only if the post office knows what address goes with their name (the analogy only works if everyone in the world has a unique name).  So, in order for URLs to work, we set up servers that keep lists of which URLs correspond to which IP addresses, and then tell our computers to go to those servers to ask what IP address is associated with `umhau.github.io`.  These are called Domain Name System (DNS) servers, and we have to explicitly tell our computers which _DNS Servers_ they should use. 

There's some common servers, like `8.8.8.8` and `1.1.1.1`, which are hosted by Google and Cloudflare.  These are useful public services, though they're probably also extremely useful as a source of information: if you use `8.8.8.8` to figure out how to connect to each website you want to visit, then you've just told Google about your complete browsing history.  

This is all just introduction. The point is, it's inefficient and slow to send queries across the internet every time you want to visit a website. This line item in the OpenBSD configuration list is for DNS caching - which means that recent queries are stored by your router, so that if two devices both try to access `facebook.com` in a short period of time, the router will remember what was looked up by the first device, and will just send the same response to the second device. Makes things quicker, though if the IP address changes in the meantime, the cache won't update until the router thinks it's time to double-check the data.

- [ ] **Virtual Private Network** (VPN). This is going to be complicated, and definitely will merit its own post.  I'm not totally sure how to set this up, but there's some distinct pieces to it.  I want to create a virtual device, and have a wired subnet that funnels all it's data transparently throught the VPN.  That way I don't have to install the VPN software on my machines. 

I also want to set up a VPN-based LAN that I can share with my friends - a sort of darknet. 

Finally, I want to be able to connect to my home network remotely, and I wonder if a VPN is the best way to do that. However, that would mean disabling the VPN while those devices are on the home network, since otherwise there would be strange loops.

# Initial System Configuration

## Hardware Arrangement

[Hardware requirements.](https://www.openbsd.org/faq/pf/perf.html)

This is a standalone physical device with ~4 network ports and 1+ usb wifi cards attached. Internally, there's [not a lot of difference](https://www.openbsd.org/faq/faq6.html#Wireless) between the usb wifi and the built-in ethernet ports: the `/etc/hostname.<device>` for wifi gets a couple extra lines for wifi name and password, and that seems to be about it.  

Just make sure the firmware is installed.

	fw_update
	
This can't be done without an internet connection, but will make sure that if the wifi card firmware is officially supported, it is installed without issue. [Supported wifi cards](https://www.openbsd.org/faq/faq6.html#Wireless).

## package installation

Make sure we can install packages. You only need one of the following two lines; use whichever works better.

    export PKG_PATH=http://mirrors.mit.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/
    export PKG_PATH=https://plug-mirror.rcac.purdue.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/

Now we can install a package with

    pkg_add nano

Remove previously-installed packages with

    pkg_delete nano

Search for packages by name with

    pkg_info -Q nano




# Router Setup

## Network Definition

First, let's outline how I'm setting up my local network. This router is going to be accessing the outside internet through a wireless connection - remember how I mentioned that your wifi card might need firmware, that has to be downloaded from online? Yeah...that was fun.  

I'm also going to have at least two local subnets, though one of those three is going to come later: an 'insecure' subnet, that I use for gaming, video calls, and random software that won't function without strange workarounds; and a 'secure' network, that has packet filtering implemented and maybe even a transparent VPN. I'm still not sure about the division between the subnets, and I might end up wanting more - my router has 4+1 ethernet ports, so I can definitely do it - but I lose the transparency to the connected devices if I have to connect multiple cables to them. 

That's the thing: while [it's possible](https://man.openbsd.org/dhcpd.conf#REFERENCE:_DECLARATIONS) to have multiple subnets on the same physical wire, and just segregate based on MAC address, requested static IPs, fingerprinted OSes, and a default association, the best-practice is to use separate physical networks (hence the use of separate physical ethernet ports on the OpenBSD router).  This, in turn, necessitates buying and pulling multiple sets of cables, and tracking which cables are connected to which subnets (yay for colored cables).  This is feasible, but better to buy and pull two sets of cables than four or five.

Note that I would use network switches to connect the devices together: one switch for each subnet, and the OpenBSD router would be connected to each of the subnets via the specific hardware port associated with that subnet. 

All that filtering can be disruptive, if not done right, but I'd like to avoid infinite gradations of security settings on their own subnets. And thus we reach yet another classic tradeoff.  My solution is to do two for a start, 'secure' and 'insecure' and just see what's practical for each.

Thus, two local subnets. I have ethernet devices labeled `em0` through `em3`, and an `athn0` usb Wifi device.

	em0 [secure]   10.0.0.1/24
	em1 [insecure] 10.0.1.1/24
	
Each of these subnets give us 255+1 available IP addresses to work with.  I doubt my personal network will need more than that. (BTW, because it would have confused me when I was younger: the 0 in `em0` has nothing to do with the 0 in `10.0.0.1/24`, except that I liked the symmetry. Could just as easily have been `10.0.231.1/24`, or a wide variety of other ranges.)

> Although in theory any IP address can be used on the inside, it is strongly recommended that one of the address ranges defined by RFC 1918 be used. Those netblocks are:

	10.0.0.0    – 10.255.255.255  (all of net 10, i.e. 10/8)
	172.16.0.0  – 172.31.255.255  (i.e. 172.16/12)
	192.168.0.0 – 192.168.255.255 (i.e. 192.168/16)

([source](https://man.openbsd.org/pf.conf#nat-to))

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

## Dynamic Host Configuration Protocol (DHCP)

That's a really fancy way of saying 'this is the program that gives devices IP addresses'.  Since we're building a router, that's this baby.

First, enable the daemon (what's a daemon? See [here](https://en.wikipedia.org/wiki/Daemon).  Wait, no, see [here](https://en.wikipedia.org/wiki/Demon_(thought_experiment)). Nope, [this is it](https://en.wikipedia.org/wiki/Daemon_(computing)#Terminology).). 

    rcctl enable dhcpd
	
However, where should the router provide the DHCP service? Should it give out IP addresses to the whole Internet, over the `athn0` connection? We need to tell it where to operate. We want it to give out IP addresses on the `secure network` and the `insecure network`. We can tell it this using the associated ethernet ports:

    rcctl set dhcpd flags em0 em1
	
Now, when a device sends DHCP IP address request packets that bubble up through the `em0` or `em1` ethernet ports, the OpenBSD router will know to go ahead and answer them with a free (free as in available) IP address they can use.

Finally, even though the DHCP server knows to answer packets on those two devices, it doesn't actually know what to say: what address ranges to hand out. Should it give out `192.168.1.5`? How about `10.10.10.123`? And what should it say, when the device on the subnet wants to know the IP address of the OpenBSD router itself?  We edit the file `/etc/dhcpd.conf` to hash this out.

	option domain-name "yourdomain.net";
	
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



## Firewall: the PF Packet Filter

### Intro

Finally! The part we've all been waiting for. Previously, we've described the paths along which data may flow; now we get to be choosy, and filter the data to determine which datums get to use which paths. We generally talk about the units of data as _packets_, which have _headers_ and _bodies_.  

	+----------------------------+
	| header |        body       |
	+----------------------------+

The headers contain information like _'where the data is going'_ and _'where it came from'_ and _'what sort of data it is'_.  Sometimes there may be several layers to the header, and sometimes the body itself may be multiple packets stored together.  This often happens when the packet is being forwarded from one place to another, or when the original sender knows it has to bounce the packet through multiple intermediaries in succession.

	+--------+---------------------------+
	|        | +--------+--------------+ |
	| header | | header |     body     | |
	|        | +--------+--------------+ |
	+--------+---------------------------+

Things get more complicated when some of the parts are encrypted, or the body is itself an encrypted packet. It's all very confusing, but there's a definite logic to it: just a lot of possibilities.

	+----------+----------+----------------------------------+
	| header 1 | header 2 | header 3 |         body          |
	+----------+----------+----------------------------------+

So. We need to decide how to sort these packets, as they pass through the router. Remember, a packet can only be sorted / filtered by the router _if it passes through the router_.  Sometimes it won't, when you might think it would.

### Runtime Options

Note, `#` can be used to insert comments.

All our firewall configurations and alterations go in `/etc/pf.conf`, and are managed by...`PF`.  This is a fairly involved program, though it can, once understood, at least appear logical - if not simple.  It's best if you stop reading this post now, go over [here](https://www.openbsd.org/faq/pf/), and read through the pages of this PF user's guide. Don't try to understand everything, but read it critically. Then come back here, and the rest of this section will appear familiar - and the implementation it describes will answer questions you may have generated while reading that user's guide.  Good? Good.

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

Moving on rapidly. We're going to be dealing with three devices, so we'll enumerate them at the top of the file, with variables in case we change the ports.

    secure   = "em0"
    insecure = "em1"

Instead of setting a similar variable for the device connected to the outside internet, there's a [group name](https://man.openbsd.org/ifconfig#group) that covers the [egress point](https://www.thefreedictionary.com/egress) of the local network: `egress`. This is a built-in variable name, that automatically refers to the device we need, so we don't even have to define it - unless we're doing something weird.

>  In this case, the egress group is being used rather than a specific interface name. By doing so, the interface holding the default route (em0) will be chosen automatically. [src](https://www.openbsd.org/faq/pf/example1.html#pf)

Note that we're using `athn0` as the egress point, rather than the `em0` mentioned in the quotation.

	table <martians> { 0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16     \
			   172.16.0.0/12 192.0.0.0/24 192.0.2.0/24 224.0.0.0/3 \
			   192.168.0.0/16 198.18.0.0/15 198.51.100.0/24        \
			   203.0.113.0/24 }

This is a table of IP addresses that should not be available outside the local network. If a packet tries to get in through the egress point and provides one of these IP addresses as a source or destination address, it is certainly either malicious or badly made.  But more on that later. 

Now we're going to set some PF [options](https://www.openbsd.org/faq/pf/options.html).

	set block-policy drop
	
If we block a package, setting the `block-policy` option to `drop` [instead of](https://man.openbsd.org/pf.conf#block) some form of `return`, that means we will not send a return message saying that we blocked it: we just [ghost](https://www.urbandictionary.com/define.php?term=Ghost) it.

	set loginterface egress
	
We're going to collect some logging information on the interface(s) that are considered egress points (and considered so because the system automatically put them inside the egress group).

	set skip on lo0
	
The loopback device (`lo0`) is a virtual device that doesn't have any traffic...so we're going to just not do anything with it, and skip it.

> Skip all PF processing on interface. This can be useful on loopback interfaces where filtering, normalization, queueing, etc, are not required. This option can be used multiple times. By default, this option is not set. 

### Rules

Next we're going to do the actual packet processing; previously, we were just setting some general options, now we set up rules that run per-packet. As you read through, imagine holding a single packet in one hand, and this list of rules in the other. Where does the packet say it came from? Where does the packet say it's going? What is the format of the data it contains? 

Then, look at the list of rules, and read them from top to bottom.  Only some of the rules will match the packet: each rule says what sorts of packets it applies to, and what to do with the matching packets. Maybe one rule talks about blocking "UDP" packets, and another talks about letting all packets through that are coming out of the "em0" device. If you're holding a packet that is "UDP", and is, indeed, coming out of the "em0" device, then what do you do? One rule says to block it, another says to let it through. 

PF uses a simple solution: the _last matching_ rule wins.  Since the 'let all em0 packets through' rule came second, it gets the final say.  (This isn't actually crude, though it might seem that way at first: this allows us to define general rules first, and then precise exceptions later.  For instance, a good best-practice is to make the first rule block everything, and then later rules (which win against the older rule) create exceptions to let specific packets through.) 

There's an exception to this arrangement, however: if the rule contains the keyword `quick`, then if that rule applies to the packet you're holding, you apply that rule immediately and stop reading through the rest of the list of rules. 

	match in all scrub (no-df random-id max-mss 1440)

Gibberish, right? Not even greek to me.  Or not: 

- if we break that up, `match in all` just means it literally matches all packets; the rest (inside the parentheses) is a definition of _how_ we're supposed to [scrub](https://man.openbsd.org/pf.conf#Scrub) the matching packets - which is all of them, since every packet matches. 
- The `no-df random-id` bit deals with 'fragmented packets', which can apparently be generated by some operating systems. The `no-df` part removes the "don't fragment" bit on the packets, and the `random-id` makes sure the packets are still unique.  It's a bit strange, but there ya go. Kinda makes sense.  
- After that, the `max-mss 1440` enforces a "maximum segment size (MSS) for matching TCP packets"...which I take to mean, TCP packets can be broken into pieces, and we don't want the pieces to be too big.  Or something.  

In general, this rule 'normalizes packets'.

In case you're wondering how the syntax works (I was), there's a [section on grammar](https://man.openbsd.org/pf.conf#GRAMMAR). If you peruse that, do so from the top, down.  You'll notice that the unknown terms used in one definition are defined thereafter. It's actually fairly well-written.

	match out on egress inet from !(egress:network) to any nat-to (egress:0)

High-level: this rule 'performs network address translation, with the `egress` interface between the LAN and the public internet. Helpful? Didn't think so. 

- The `match out` part means, according to the grammar section and some `CTRL-F`-ing in the pf.conf page and the building-a-router page, to [match](https://man.openbsd.org/pf.conf#match) packets going [out](https://man.openbsd.org/pf.conf#in) (instead of in) of the router - this has nothing to do with the networks connected to the ethernet ports, but just means that the packets are physically going out of the router box; 
- [on egress](https://man.openbsd.org/pf.conf#on) means we're looking at stuff happening _on_ the network devices that are connected to the outside internet (as opposed to, say, `on em4`, or `any`, where we'd be dealing with just the specific `em4` device, or all of the devices); 
- [inet](https://man.openbsd.org/pf.conf#inet) means we're only dealing with IPV4 packets, not the newer IPV6 packet type; 
- [from !(egress:network) to any](https://man.openbsd.org/pf.conf#from) specifies the source of the packets that the rule applies to. Note that `!` is used in the standard fashion as the logical `not`, and paired with the parentheses means that we want any packet which _does not match_ egress[:network](https://man.openbsd.org/pf.conf#:network) (whatever that is). In fact, we know what `egress` means: that's a catch-all for any network interface that connects to the outside internet. When used in conjunction with the `from` keyword, the `:network` postfix refers to the networks attached to the specified interface.  So we're matching packets that _don't_ come from outside networks, and are going `to` anywhere. 

We've come to the end of the filter-part of this rule, so let's summarize: this rule matches IPV4 packets that are physically leaving the router, on the network device connected to the outside internet, coming _from_ anywhere that's not the outside internet, and going _to_ anywhere at all. 

- [nat-to (egress:0)](https://man.openbsd.org/pf.conf#nat-to). Here, we're finally specifying _what to do_ with the packets we've matched. Up 'til now, we've only been trying to specify which packets we wanted to do _something_ with: well, here's that something. `nat-to` is one of several options that [translate](https://man.openbsd.org/pf.conf#Translation) packet addresses: that is since the computer on the outside internet and the computer on the inside internet have IP addresses in different ranges, the address of each makes no sense to the other.  

An analogy, using physical addresses: one of the machines is at the address, `1234 Inconceivability Lane, Unbelievable, OH`, and regularly sends mail to other buildings around the country.  The other machine is at a _room number_, in a multi-building research facility. Its address is, `Room 23, Floor 12, Building 10`, and it regularly sends mail to other rooms in other floors and buildings _within the campus_.  They can each get replies because they include return addresses.  In order for these two machines to send mail _to eachother_, some kind of translation facility is required. Since the latter machine is located in the less-generalized environment, that campus has to run an address translation for the campus.  

That address translation is what makes it possible for mail to travel between the machines. When the machine at `Room 23, Floor 12, Building 10` wants to send mail to `1234 Inconceivability Lane, Unbelievable, OH`, it uses the full address; however, how does the machine at `1234 Inconceivability Lane, Unbelievable, OH` know where to send the return? It doesn't know of any address which could do anything with `Room 23, Floor 12, Building 10`, and the post office certainly couldn't do anything with such a return address.  The solution is the address translator: the address translator gets an outside address for the whole campus (`5678 Somewhere Circle, Elsewhere, ID`), all outgoing mail is intercepted, and the return address is modified to be the address of the translator.  Then the outside machine knows where to send its replies.  This is the purpose of the [NAT](https://en.wikipedia.org/wiki/Network_address_translation#One-to-many_NAT).

To finish up: we're familiar with `egress`, and `:0` translates to 'do not include the interface aliases' - which, I think, means that `egress:0` gets translated directly into the IP address that the OpenBSD router has on the outside network.  The use of parentheses, as `(egress:0)]`, means that this rule is updated whenever the `egress` interface changes its IP address (i.e., if the ISP decides to change the assigned IP address, we don't have to go in an reboot the ruleset).  The `nat-to` phrase means that it does the job of that 'address translator' - it looks at the return address of each matching packet, and changes that return address into something else: in this case, into `egress:0`, which is the IP address of the OpenBSD router itself. 

Syntax clarification: the `nat-to` is a connective: it means, any of those packets that match the rule are converted into something else:

	[ matched packets ] nat-to [ translated packets ]

Recall above, that this rule matches IPV4 packets that are physically leaving the router, on the network device connected to the outside internet, coming _from_ anywhere that's not the outside internet, and going _to_ anywhere at all. We take all of those packets, and convert their 'return addresses' into the IP address of the OpenBSd router.

A final question, that I can imagine might percolate: when the router gets replies from outside computers, that are heading to internal computers, how does it know where to send them? It stripped out any return addresses it might have used. The answer is, it keeps a 'state table', which effectively means that the router tracks every connection of every computer inside its network - in this way, it's able to compare the incoming packets to the connections that it knows exists, and route the packets correctly.

Well, that was the tough one. Here's the rest.

    antispoof quick for { egress $secure $insecure }

It's possible to write a packet that has false information in its header, including the wrong return address, just like it's possible (but not legal!) to write a letter and put someone else's return address on it.  This rule checks for such 'spoofing': to use the mailing address analogy, if the 'address translator' facility received a letter through the postal service of the outside world that was addressed like it was _from_ one of the buildings on-campus, they would immediately know without a doubt that it could not possibly be legitimate - and yet, if it had been passed through to its intended recipient, it might have been very convincing.  So, this is what `antispoof` does: when it sees such mail/packets, it just drops them silently. Note also the use of `quick`: as mentioned earlier, this means the rule is immediately implemented, and the rest of the rule list is ignored.

The use of braces `{}` means that the rule is generated for each of the items inside. This is combinatoric, in that a rule with multiple sets of braces will multiply its rules: 

	rule-command { a b c d } and-also { x y z }

Expands to:

	rule-command a and-also x
	rule-command a and-also y
	rule-command a and-also z

	rule-command b and-also x
	rule-command b and-also y
	rule-command b and-also z

	rule-command c and-also x
	rule-command c and-also y
	rule-command c and-also z

	rule-command d and-also x
	rule-command d and-also y
	rule-command d and-also z

I had to check for an example of that to be sure, but that does, indeed, seem to be how the braces are expanded.

	block in quick on egress from <martians> to any

Remember that table we defined near the beginning? Here's where we use it. This rule is similar to the antispoofing rule, in that we have a list of IP address ranges that should never be available on the outside network, and if we ever get an incoming packet that says it's from one of those addresses, we know it's either badly-made or malicious, so we block it. Only if it's coming in on the `egress` device(s); any destination merits a block.

	block return out quick on egress from any to <martians>

Similarly, we block any packet that's trying to leave the local network to go to any of those invalid addresses. This is different from a packet communicating with an external server: in both of these rules, the external server is known to be invalid. 

	block all

This was explained earlier: since the last matching rule wins, after this (fairly obvious) rule, we define some rules to _allow in_ only the traffic we actually want.  A whitelist is far more effective here than a whack-a-mole blacklist.

	pass out quick inet

This means that all IPV4 traffic leaving the OpenBSD router (that's more-or-less trivially 'everything', since this network doesn't deal with IPV6) will be allowed to leave.  So, if the packet is trying to head out in the direction of the open internet, or if it's trying to leave the router in the direction of one of the local subnets, it will be allowed to leave.  This works because we're going to filter the packets as they come in, rather than when they leave. No need to analyze each packet twice.

There's also a wrinkle here that might be confusing on the first read: this last rule seems to immediately allow all outbound packets to pass through - but what about the previous antispoof rule, and the 'martians' rules? Doesn't this `pass` rule come later and overwrite them? The answer is, notice that they're using the `quick` keyword: if the antispoof or 'martians' rules are matched, the rest of the list of rules is immediately ignored, and the packet is dropped. This `pass out quick inet` rule only applies to packets that didn't match those rules with `quick`.  

    pass in on { $secure $insecure } inet

Now we analyze the packets as they come into the router (`pass in`).  We're only looking at the packets on the internal networks, for now, so we restrict the rule to those.  Also note that we're only looking at the IPV4 addresses. If we had an IPV6 network, we'd leave that `inet` bit off, I think.

And there we go! That's the basic version.  No real filtering of the secure network, so far, but that's for a later post.


## DNS

### DNS Cache service

> While a DNS cache is not required for a gateway system, it is a common addition to one. When clients issue a DNS query, they'll first hit the unbound(8) cache. If it doesn't have the answer, it goes out to the upstream resolver. Results are then fed to the client and cached for a period of time, making future lookups of the same address quicker.

Enable the cache service.

    rcctl enable unbound

Then set up the configuration file: `/var/unbound/etc/unbound.conf`.

    server:
        interface: 10.0.0.1
        interface: 10.0.1.1
        interface: 127.0.0.1
        access-control: 10.0.0.1/24 allow
        access-control: 10.0.1.1/24 allow
        do-not-query-localhost: no
        hide-identity: yes
        hide-version: yes

    forward-zone:
            name: "."
            forward-addr: 1.2.3.4  # IP of the upstream resolver

That's complicated: let's unpack it.

    server:
	  ⋮
    forward-zone:
      ⋮

The Unbound DNS validating resolver configuration file has multiple configuration zones. Each of these zones... No. Let's back up for a sec.  

### config file review

We know that we're trying to set up a cache for DNS queries; we talked about that earlier. We also know, more or less, what a DNS query and a DNS resolver are.  However, this '[unbound](https://man.openbsd.org/unbound)' DNS cache service is new.  

> Unbound is a caching DNS resolver.

> It uses a built in list of authoritative nameservers for the root zone (.), the so called root hints. On receiving a DNS query it will ask the root nameservers for an answer and will in almost all cases receive a delegation to a top level domain (TLD) authoritative nameserver. It will then ask that nameserver for an answer. It will recursively continue until an answer is found or no answer is available (NXDOMAIN). For performance and efficiency reasons that answer is cached for a certain time (the answer's time-to-live or TTL). A second query for the same name will then be answered from the cache. Unbound can also do DNSSEC validation.

There's also a config file that we use for unbound: [unbound.conf](https://man.openbsd.org/unbound.conf).  In general, the syntax of that file seems to be fairly simple:

> The file format has attributes and values. Some attributes have attributes inside them. The notation is: attribute: value.  There must be whitespace between keywords. Attribute keywords end with a colon ':'. An attribute is followed by a value, or its containing attributes in which case it is referred to as a clause. Clauses can be repeated throughout the file (or included files) to group attributes under the same clause.

Also, just in case the config file got complicated, there's a tool for checking it before use: [unbound-checkconf]().

Are we good now? 

### config file walkthrough

Back to unpacking the contents of that `unbound.conf` file.

    server:
	  ⋮
    forward-zone:
      ⋮

These are, according to that quote on the syntax above, general top-level attributes: they indicate that the settings we're putting inside each are related to that aspect of the DNS resolver. In the first case, we're telling `unbound` about the environment that the _server_ is in: the networks it's connected to, and things it should and should not be doing. 

In the second case, the `forward-zone` clause describes where to forward DNS queries; since this OpenBSD router doesn't have it's own list of IP/URL conversions, it has to send those queries elsewhere. Best it can do is just answer repeats.  

	interface: 10.0.0.1
	interface: 10.0.1.1
	interface: 127.0.0.1

This is where the DNS resolver should listen for DNS queries. Notice that not only is it listening to it's IP address on both of the subnets (for any DNS queries directed to those IP addresses), but it's also listening on the `localhost` address: this means that when the OpenBSD router itself tries to contact an external site, the DNS cache it's running will answer it, if possible.

> Interface to use to connect to the network. This interface is listened to for queries from clients, and answers to clients are given from it. Can be given multiple times to work on several interfaces. If none are given the default is to listen to localhost. If an interface name is used instead of an ip address, the list of ip addresses on that interface are used. The interfaces are not changed on a reload (kill -HUP) but only on restart. A port number can be specified with @port (without spaces between interface and port number), if not specified the default port (from port) is used. [src.](https://man.openbsd.org/unbound.conf#interface:)

	access-control: 10.0.0.1/24 allow
	access-control: 10.0.1.1/24 allow

This is another matching scenario.  The `allow` action means that the DNS cache (the OpenBSD machine) is allowed to answer queries that originate from the listed network range. If the packet comes from somewhere not inside any listed network, the packet is denied, and not answered. 

> The most specific netblock match is used

	do-not-query-localhost: no

This means that the localhost - the OpenBSD machine - can be sent DNS queries, by processes on itself. [By default](https://man.openbsd.org/unbound.conf#do~7) this is off.

	hide-identity: yes
	hide-version: yes

Apparently there's types of DNS queries that ask for indentifying information of the OpenBSD server. They are refused when these settings are `yes`.  

    forward-zone:
            name: "."
            forward-addr: 1.2.3.4  # IP of the upstream resolver

This is where we specify the actual DNS resolver, that keeps the list of URLs and associated IP addresses. In a simple case, like ours, we only need a single forward zone, and we can make it just foward everything to one place to make it easy.  That's what's happening here: by setting the `name` attribute to `'.'`, and giving a single `forward-addr` target, we're using a shortcut that indicates we just want everything forwarded to one place. 

### The upstream DNS resolver

This is going to be a provider that you trust. Often, your ISP will provide this service; check with them to figure out what the IP address is. Alternately, you could use a public service like the ones mentioned earlier, by Cloudflare or Google; time will tell just how idiotic trusting those services would be.

There's some interesting resources in this area. In fact, it even looks like it's [easier](https://zwischenzugs.com/2018/01/26/how-and-why-i-run-my-own-dns-servers/_) [than](https://docs.pi-hole.net/guides/unbound/) [I](https://jamsek.dev/posts/2019/Jul/28/openbsd-dns-server-with-unbound-and-nsd/) [thought](https://www.petekeen.net/how-i-run-my-own-dns) to run your own DNS resolver - to keep your own list of the URLS that exist in the world. 

There's also DNS providers which will filter out various types of websites (malicious, porn, etc) for you.  These might be interesting to use, in specific situations. There's also [this guy](https://www.reddit.com/r/sevengali/comments/8fy15e/dns_cloudflare_quad9_etc/) on reddit who really wanted people to read his essay about which DNS providers to use. Might be crazy, might be monomaniacal, might be altruistic; whichever way, it's worth a read.

For now, I'm just going to stick with cloudflare (`1.1.1.1`), though I might try my hand at running my own DNS system in the future.  Whatever you do, don't use Google.


### nameserver configuration

Make sure to put a proper [nameserver](https://en.wikipedia.org/wiki/Name_server) in the `/etc/resolv.conf` [file](https://man.openbsd.org/resolv.conf).  

Since we're setting up a DNS cache on the router, we may want the router itself to use that cache. In that case, set the router's nameserver to itself: `127.0.0.1`. 

    search example.org
    nameserver 127.0.0.1

And we're done!
