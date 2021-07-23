These are the settings for an OpenBSD network gateway device. It includes several services. 

- dhcp server. Use an unusual IP address range
- VPN (with wireguard)
- router?

Notes & Resources
-----------------

Useful links: [openbsd networking](https://www.openbsd.org/faq/faq6.html), 

Dynamic Host Configuration Protocol (DHCP0 servers assign IP addresses to new network devices. Domain Name System (DNS) servers communicate with clients to translate URLS into IP addresses.

Hardware Arrangement
--------------------

This is a VM, with two network devices: one passthrough, on the main subnet, and one internal virtual device for a temporary faux local network.

CONFIGURATIONS
==============

### packages

Make sure we can install packages. 

    export PKG_PATH=http://mirrors.mit.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/
    export PKG_PATH=https://plug-mirror.rcac.purdue.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/
    
### network devices

Both ethernet connections should be active.  The below refers to a virtual network device, hosted by xen.

    echo dhcp > /etc/hostname.xnf1

Use `sh /etc/netstart` to apply changes.

### DNS Resolution

Make sure to put a proper [nameserver](https://en.wikipedia.org/wiki/Name_server) in the `/etc/resolv.conf` [file](https://man.openbsd.org/resolv.conf).  E.g., `8.8.8.8`.

    search contoso.org
    nameserver 8.8.8.8

## DHCP Server

To use OpenBSD as a DHCP server, enable the dhcpd daemon at startup. 

    rcctl enable dhcpd

To configure the IP ranges, and the other settings specific to the assignation of IP addresses to devices, see the [DHCP configuration file](https://man.openbsd.org/dhcpd.conf).  See the [description](https://man.openbsd.org/dhcpd.conf#DESCRIPTION) section of the relevant OpenBSD man page for the config file syntax.


```bash
    global parameters...
    option domain-name "isc.org";
    option domain-name-servers ns1.isc.org, ns2.isc.org;

    shared-network ISC-BIGGIE {
    shared-network-specific parameters ...
    subnet 204.254.239.0 netmask 255.255.255.224 {
        subnet-specific parameters ...
        range 204.254.239.10 204.254.239.30;
    }
    subnet 204.254.239.32 netmask 255.255.255.224 {
        subnet-specific parameters ...
        range 204.254.239.42 204.254.239.62;
    }
    }

    subnet 204.254.239.64 netmask 255.255.255.224 {
    subnet-specific parameters ...
    range 204.254.239.74 204.254.239.94;
    }

    group {
    group-specific parameters ...
    host zappo.test.isc.org {
        host-specific parameters ...
    }
    host beppo.test.isc.org {
        host-specific parameters ...
    }
    host harpo.test.isc.org {
        host-specific parameters ...
    }
    }
```