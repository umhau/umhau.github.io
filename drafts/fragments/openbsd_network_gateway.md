# OpenBSD Router

One of my clients has a PFSense box and Active Directory box on-premise. I'd like to recombine their functions into an OpenBSD box for networking, and a Samba box (or two) for AD user authentication and the fileserver. This post covers the process of working out how to build the OpenBSD box.

I remain blown away by the quality of the OpenBSD documentation. I'm going to quote some long-form sections below for various items I need to remember. Makes it easier than just linking them, and having to jump between web pages. 

The following functions should be included in the OpenBSD box.

- DHCP server. This service, I think, was previously performed by the Windows server -- for some reason.  
- DNS caching. Not sure if this is currently done; don't think so. Either way, looks relatively simple to implement and should be a decent improvement.
- VPN. This will be a definite win, since I plan to use wireguard. Probably more complicated, but maybe not by much.
- Packet routing. This is where things get a little more vague, since I'm not totally up with my networking knowledge. Is this what's technically called the router? I have another system to manage the wifi routers. But, I think the interface between the WAN and the LAN is covered by this point and the next:
- Network Gateway; because I plan to physically connect this box to the cable leading out of the building.
- Firewall. This is another reason I chose OpenBSD specifically, because the [`pf` Packet Filter](https://www.openbsd.org/faq/pf/) is so highly regarded.

I'll consider the above my checklist for 'stuff to implement on the OpenBSD box'.  Some of it is a higher priority, since not all of it needs to be present before I can do the change over (e.g., there's no VPN right now that's any good, so removing that won't be a big deal).   I do want to implement the Samba boxes sooner than later; I think those can/should be FreeBSD boxes to maximize the reliability and general 'hands-off-ness'.  

- [ ] [Network Address Translation](https://www.openbsd.org/faq/pf/nat.html) (NAT) is a way to map an entire network (or networks) to a single IP address. It is necessary, for example, when the number of IP addresses assigned to a customer by an internet service provider is less than the total number of computers in that household that need internet access.   An OpenBSD system doing NAT will have at least two network interfaces: one to the internet and the other for the internal network. NAT will be translating requests from the internal network so they appear to all be coming from the OpenBSD NAT system. 
- [ ] Since NAT is almost always used on routers and network gateways, it will probably be necessary to enable IP forwarding so that packets can travel between network interfaces on the OpenBSD machine.
- [ ] [Port Forwarding](https://www.openbsd.org/faq/pf/rdr.html).  Redirection allows incoming traffic to be sent to a machine behind the NAT gateway. 


## Notes & Resources

Useful links: [openbsd networking](https://www.openbsd.org/faq/faq6.html), 

Dynamic Host Configuration Protocol (**DHCP**) servers assign IP addresses to new network devices, usually on a Local Area Network (LAN). Domain Name System (**DNS**) servers communicate with clients to translate URLS into IP addresses, usually on a Wide Area Network (WAN).


### Network Address Translation (NAT)

[Source](https://www.openbsd.org/faq/pf/nat.html)

Network Address Translation (NAT) is a way to map an entire network (or networks) to a single IP address....An OpenBSD system doing NAT will have at least two network interfaces: one to the internet and the other for the internal network. NAT will be translating requests from the internal network so they appear to all be coming from the OpenBSD NAT system.   

When a client on the internal network contacts a machine on the internet, it sends out IP packets destined for that machine. These packets contain all the addressing information necessary to get them to their destination. NAT is concerned with these pieces of information: source IP address and source TCP or UDP port.

When the packets pass through the NAT gateway, they will be modified so that they appear to be coming from the NAT gateway itself. The NAT gateway will record the changes it makes in its state table so that it can reverse the changes on return packets and ensure that return packets are passed through the firewall and are not blocked.   Neither the internal machine nor the internet host is aware of these translation steps. To the internal machine, the NAT system is simply an internet gateway. To the internet host, the packets appear to come directly from the NAT system. It is completely unaware that the internal workstation even exists. 






### Hardware Arrangement

This is a VM, with two network devices: one passthrough, on the main subnet, and one internal virtual device for a temporary faux local network.  Eventually, this will be a standalone physical device with 5+ network ports for various subnets; for now, I'm just doing testing and experimentation and the VM serves my needs pretty well.  

[Hardware requirements.](https://www.openbsd.org/faq/pf/perf.html)

# Implementation

## Basic Setup of OpenBSD

### packages

Make sure we can install packages. 

    export PKG_PATH=http://mirrors.mit.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/
    export PKG_PATH=https://plug-mirror.rcac.purdue.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/

Now we can install a package with

    pkg_add nano

Remove previously-installed packages with

    pkg_delete nano

Search for packages by name with

    pkg_info -Q nano

### network devices

Both ethernet connections should be active.  I think I may have used `ifconfig xnf1 up` to activate the secondary interface, but I'm not sure...too many false starts, too many different things getting built. The below refers to a virtual network device, hosted by xen.

    echo dhcp > /etc/hostname.xnf1

Use `sh /etc/netstart` to apply changes.

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

