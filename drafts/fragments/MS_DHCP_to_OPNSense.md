I'm moving a network from an ancient Microsoft DHCP server to OPNSense. I would set up an independent DHCP server, but for now the primary criteria is a) keep things running with minimum downtime and b) make sure other people can figure out how to use it (an OpenBSD default installation would be more ideal, but I really don't think it's a user-friendly choice).

So what I'm doing here is making sure that I'll remember how this works: export the reservations list off windows, get it onto my personal laptop, insert the relevant bits into an OPNSense backup file, and restore OPNSense from the doctored backup.

Oh - by the way, Windows DHCP doesn't include MAC addresses in the export, so we'll be getting those by scanning the network.

export from Windows DHCP
------------------------

Right click on the Reservations folder and select Export List. If you don't know how to get there, you have much bigger problems that I can't help you with.

![DHCP reservations export](/images/networking/MS_DHCP_export_reservations.png)

You can also get the mac addresses: since this is the DHCP machine, it'll have the ARP entry cached for each machine on the network that used the server for DHCP, and that's exactly the same set of machines you need MAC addresses for.

```
ARP.EXE -a > macs.txt
```

get it onto the personal laptop 
-------------------------------

I'll leave the getting of the file to your imagination. 

The contents is in this format:

```
Reservations
[192.168.1.11] hostname01.contoso.com
[192.168.1.12] hostname02.contoso.com
```

Go ahead and trim off that first line, since it'll just get in the way later.

get the associated MAC addresses
--------------------------------

We'll use `arping` to get the MAC addresses from the IP addresses.

The other useful thing about `arping` is that you can specify the network interface it should run on. In my specific use case, that's really nice because I'm connected to two different overlapping subnets and I'd otherwise have to disconnect from one of them before I could use this.

```
sudo xbps-install -S iputils
ifconfig
sudo arping -I wlp3s0 -f -c 1 192.168.1.14
```

Note, though, that this will only get you the mac address for machines that are currently online. For the rest, go back to the windows server and run this command to dump the ARP table to a text file:

```powershell
ARP.EXE -a > mac_addresses
```

Then export that to the dev machine, just like the DHCP reservations.

As a script:
```
