---
layout: post
title: Network Interface Madness
author: umhau
description: "Insanity awaits. This hurt my brain."
tags: 
- tcpdump
- networking
- Linux
categories: walkthroughs
---

Well, this was fun to write. I'm trying to do some server automation, and part of the process is automatically figuring out which network interfaces to bring up. You might say, _"that's easy! just run ifconfig and parse the results. Bing, bang, boom, done."_  But there's a few problems with that approach, and first among them is that we aren't assuming the existence of any kind of L3 network. In that case, how do you know which of your interfaces are on the same switch? What if the machine is on multiple L2 networks? What if you only care about infiniband interfaces, or want to ignore wifi? _What if there's no DHCP server?_

Anyway, that's what I had to deal with.

To solve the problem, I wrote a very ugly script. If you don't like it....well, constructive analysis always welcome. To use it, specify the _types_ of interfaces you want to analyze and about how much time it should take.

```shell
iface-groups -i eth -i ib -t 3
```

The output is a little strange. The problem with the data involved is that it's inherently 2-dimensional; I want to know which interfaces are grouped together. That doesn't lend itself well to a linear output. So, on every sent to STDOUT, I'm printing a space-separated list of all interfaces that are connected on the same L2 network. For example:

```shell
$ iface-groups -i eth -t 3

eth0 eth2
eth1 eth3 eth4
```
You can parse this pretty well in a `while read` loop, like so:

```shell
iface-groups -i eth -t 3 | while read group
do

    echo "these interfaces can see only each other: $group"

done
```

Finally, you may be wondering about the available interface types. Well, you can read the script, or I'll just list them out below. You can guess which is which, because I really don't feel like specifying them right now. I just wrote this whole thing, gosh darn it!

```shell
echo -e "Available interface types:"
echo -e "\teth, wlan, bridge, vlan, bond, tap, dummy, ib, ibchild, ppp,"
echo -e "\tipip, ip6tnl, lo, sit, gre, irda, wlan_aux, tun, isdn, mip6mnha"
```

Anyway, that's all a nice little prelude to actually dumping the script here. I got no idea what the license is; the type identification was pulled from stack overflow and the original source link is dead. So whatever.  If you want an updated version, you'll have to hunt through my github repos: I probably won't update this post, and the project it's for is still under wraps. You'll have to check back in a few years when it's finally presentable.

```shell
#!/bin/bash
# written by me on October 1, 2022. Do what you will, for I have already won.

# enumerates the properties of each network interface
# eventually, it may be possible to assign rules on a per-network basis
# i.e., all ifaces on 10.111.13/24 should request DHCP
# unless, that's better done as a set of logic outside this program

# we need to know:
# - which interfaces are wired
# - which interfaces are connected
# - which interfaces are on the same L2 network

# ASSUMPTION: one interface is NOT connected to multiple L2 switches

set -e

help () {

    echo -e "usage:"
    echo -e "\t-i , --ifacetype=[TYPE]"
    echo -e "\t-t , --timelimit=[seconds]"
    echo -e "Multiple interface types may be specified, like so:"
    echo -e "\tiface-groups -i eth -i tun -t 5"
    echo -e "Available interface types:"
    echo -e "\teth, wlan, bridge, vlan, bond, tap, dummy, ib, ibchild, ppp,"
    echo -e "\tipip, ip6tnl, lo, sit, gre, irda, wlan_aux, tun, isdn, mip6mnha"

}

timelimit="$1" ; [ -z "$timelimit" ] && timelimit='4'

arp_period='1'

ip_address_prefix='203.0.113'

#         +----------------------+----------------------------+
#         | Attribute            | Value                      |
#         +----------------------+----------------------------+
#         | Address Block        | 203.0.113.0/24             |
#         | Name                 | Documentation (TEST-NET-3) |
#         | RFC                  | [RFC5737]                  |
#         | Allocation Date      | January 2010               |
#         | Termination Date     | N/A                        |
#         | Source               | False                      |
#         | Destination          | False                      |
#         | Forwardable          | False                      |
#         | Global               | False                      |
#         | Reserved-by-Protocol | False                      |
#         +----------------------+----------------------------+
# 
#         Table 14: TEST-NET-3

ifacetype=eth timelimit=3 lopts=ifacetype:,timelimit: sopts=i:t:

PARSED=$(getopt --options=$sopts --longoptions=$lopts --name "$0" -- "$@")

eval set -- "$PARSED"

while true; do case "$1" in

    -i|--ifacetype) 

        # ifacetype="$2"
        allowed_iface_types="${allowed_iface_types:+$allowed_iface_types } $2"
        shift 2
        ;;

    -t|--timelimit) timelimit="$2"  ; shift 2 ;;

    --) shift ; break ;;
    *)  exit 1 ;;

esac done

# viable_ifaces="${viable_ifaces:+$viable_ifaces } $interface"

# allowed_iface_types=(
#     eth
#     ib
#     tun
#     tap
#     wlan
# )

[ -z "$allowed_iface_types" ] && help && exit 1

tempfile=/tmp/iface_enumeration
groupingfolder=/tmp/iface_enumeration_groups

rm -rf $tempfile $groupingfolder
mkdir -p $tempfile
mkdir -p $groupingfolder

if ! command -v tcpdump &>/dev/null ; then echo "tcpdump required" ; exit 2 ; fi

sudo -v

get_iface_type () {
    
    # function came from a dead link via stackoverflow
    # http://gitorious.org/opensuse/sysconfig/blobs/master/scripts/functions

    local IF=$1 TYPE
    test -n "$IF" || return 1
    test -d /sys/class/net/$IF || return 2
    case "`cat /sys/class/net/$IF/type`" in
            1)
                TYPE=eth
                # Ethernet, may also be wireless, ...
                if test -d /sys/class/net/$IF/wireless -o \
                        -L /sys/class/net/$IF/phy80211 ; then
                    TYPE=wlan
                elif test -d /sys/class/net/$IF/bridge ; then
                    TYPE=bridge
                elif test -f /proc/net/vlan/$IF ; then
                    TYPE=vlan
                elif test -d /sys/class/net/$IF/bonding ; then
                    TYPE=bond
                elif test -f /sys/class/net/$IF/tun_flags ; then
                    TYPE=tap
                elif test -d /sys/devices/virtual/net/$IF ; then
                    case $IF in
                      (dummy*) TYPE=dummy ;;
                    esac
                fi
                ;;
           24)  TYPE=eth ;; # firewire ;; # IEEE 1394 IPv4 - RFC 2734
           32)  # InfiniBand
            if test -d /sys/class/net/$IF/bonding ; then
                TYPE=bond
            elif test -d /sys/class/net/$IF/create_child ; then
                TYPE=ib
            else
                TYPE=ibchild
            fi
                ;;
          512)  TYPE=ppp ;;
          768)  TYPE=ipip ;; # IPIP tunnel
          769)  TYPE=ip6tnl ;; # IP6IP6 tunnel
          772)  TYPE=lo ;;
          776)  TYPE=sit ;; # sit0 device - IPv6-in-IPv4
          778)  TYPE=gre ;; # GRE over IP
          783)  TYPE=irda ;; # Linux-IrDA
          801)  TYPE=wlan_aux ;;
        65534)  TYPE=tun ;;
    esac
    # The following case statement still has to be replaced by something
    # which does not rely on the interface names.
    case $IF in
        ippp*|isdn*) TYPE=isdn;;
        mip6mnha*)   TYPE=mip6mnha;;
    esac
    test -n "$TYPE" && echo $TYPE && return 0
    return 3
}

# for every interface on the system
for interface in /sys/class/net/*
do

    interface=$(basename $interface)

    # figure out what it is: wifi? ethernet? virtual bridge? infiniband?
    iface_type=$(get_iface_type $interface)

    # for each of the useful interface types, specified above (or in an arg)
    for allowed_iface_type in ${allowed_iface_types[@]}
    do

        # if the interface we're looking at is one of those allowed
        if [ "$iface_type" == "$allowed_iface_type" ]
        then

            # if the interface is connected to something: switch, router, etc
            if tcpdump --list-interfaces | grep $interface | grep -q 'Running'
            then

                # add it do the list of viable interfaces
                viable_ifaces="${viable_ifaces:+$viable_ifaces } $interface"

            fi

            # don't check more types after a match: "there can be only one"
            break

        fi

    done

done

ip_iterator=0

declare -A iface_ip

starttime=$(date +%s)

# for each viable interface we found
for interface in ${viable_ifaces[@]}
do

    # create a unique, unused ip address (taken from TEST-NET-3, RFC 6890)
    ip_iterator=$((ip_iterator+1))
    ip_address="$ip_address_prefix.$ip_iterator"

    # associate that ip address with the current interface
    iface_ip+=(["$ip_address"]="$interface")

    # start listening on that interface for ARP requests
    sudo timeout $timelimit tcpdump --immediate-mode -i $interface arp > $tempfile/$interface 2>/dev/null &

    # start sending ARP requests for the unique IP address on that interface
    sudo arping -I $interface -w $timelimit $ip_address &>/dev/null &

done

# total time it took to start the listeners and senders
endtime=$(date +%s)
initializationtime=$(( $endtime - $starttime ))

# wait for the listeners and senders to finish
sleep $(($timelimit + $initializationtime + 1))

# for each viable interface, get the file with the results from the listener
for ifacefile in $tempfile/*
do

    ifacename=$(basename $ifacefile)

    # if the iface is not already in a group of ifaces that can see each other
    if ! grep -q $ifacename $groupingfolder/* 2>/dev/null
    then

        # create a new group with just that interface
        echo $ifacename > $groupingfolder/$(date +%s%N)

    fi

    # for each ARP request seen by this interface, get the IP address requested
    grep $ip_address_prefix $ifacefile | cut -d ' ' -f 5 | while read ipaddress
    do

        # get the group file of the interface that saw the request
        groupfile=$(grep -l $ifacename $groupingfolder/* 2>/dev/null)

        # convert the ip address to the sender interface and add it to the group
        echo ${iface_ip[$ipaddress]} >> $groupfile

    done

done

# for each group of interfaces that we collected
for group in $groupingfolder/*
do 

    # filter out duplicate interfaces within the group and print to stdout 
    echo $(sort $group | uniq | xargs)

done


```