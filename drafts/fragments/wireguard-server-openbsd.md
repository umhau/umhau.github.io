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

