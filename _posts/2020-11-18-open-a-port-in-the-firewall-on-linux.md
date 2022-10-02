---
layout: post
title: Open a port in the firewall on linux
author: umhau
description: "watch your security"
tags: 
- ufw
- linux
- firewall
categories: memos
---

Check the status of the firewall:

```bash
ufw status
```

Turn the firewall on, off, or restart it. Use the `--dry-run` option to see what happens before you do it for real.

```bash
ufw [--dry-run] enable|disable|reload
```

Users can specify rules using either a simple syntax or a full syntax. The simple syntax only specifies the port and optionally the protocol to be allowed or denied on the host. 

Both syntaxes support specifying a comment for the rule. For existing rules, specifying a different comment updates the comment and specifying '' removes the comment.

```bash
ufw allow 22 comment 'ssh should be on by default'
```

### simple syntax

This rule will allow tcp and udp port 53 to any address on this host:

```bash
ufw allow 53
```

To specify a protocol, append '/protocol' to the port. For example:

```bash
ufw allow 25/tcp
```

This will allow tcp port 25 to any address on this host. ufw will also check /etc/services for the port and protocol if specifying a service by name. Eg:

```bash
ufw allow smtp
```

ufw supports both ingress and egress filtering and users may optionally specify a direction of either in or out for either incoming or outgoing traffic. If no direction is supplied, the rule applies to incoming traffic. Eg:

```bash
ufw allow in http
ufw reject out smtp
ufw reject telnet comment 'telnet is unencrypted'
```

### full syntax

Users can also use a fuller syntax, specifying the source and destination addresses and ports. 

```bash
sudo ufw allow from <target ip address> to <destination ip address> port <port number> proto <protocol name>
```

For example:

```bash
ufw deny proto tcp to any port 80
```

This will deny all traffic to tcp port 80 on this host. Another example:

```bash
ufw deny proto tcp from 10.0.0.0/8 to 192.168.0.1 port 25
```

This will deny all traffic from the RFC1918 Class A network to tcp port 25 with the address 192.168.0.1.

```bash
ufw deny proto tcp from 2001:db8::/32 to any port 25
```

This will deny all traffic from the IPv6 2001:db8::/32 to tcp port 25 on this host. IPv6 must be enabled in /etc/default/ufw for IPv6 firewalling to work.

```bash
ufw deny in on eth0 to 224.0.0.1 proto igmp
```

This will deny all igmp traffic to 224.0.0.1 on the eth0 interface.

```bash
ufw allow in on eth0 to 192.168.0.1 proto gre
```

This will allow all gre traffic to 192.168.0.1 on the eth0 interface.

```bash
ufw allow proto tcp from any to any port 80,443,8080:8090 comment 'web app'
```

The above will allow all traffic to tcp ports 80, 443 and 8080-8090 inclusive and adds a comment for the rule. When specifying multiple ports, the ports list must be numeric, cannot contain spaces and must be modified as a whole. Eg, in the above example you cannot later try to delete just the '443' port. You cannot specify more than 15 ports (ranges count as 2 ports, so the port count in the above example is 4).

Allow traffic from a particular range of IP addresses: 

```bash
sudo ufw allow from 192.168.1.0/24
```

### source

Nearly everything above was taken straight from `man ufw`, with one exception. The first full syntax example was found online because the man pages didn't make it clear what `proto` meant. Super confusing. 