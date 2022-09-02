My company needs a vpn. There's easy ways to do this, and there's hard ways to do this; and there's middling ways that actually get the job done while remaining scrutable to those who come after.

1. Build a physically separate OpenBSD box with 2+ ethernet ports.
2. Use a subnet somewhere deep in the 10/8 range for the VPN clients, matching the size of the primary subnet, but only assign clients to a small subnet within it.
3. Use wireguard to connect to outside clients and attach them to the VPN's subnet.
4. Use network address translation between the whole primary network and the whole vpn subnet.

A diagram of what the subnet craziness means:

  +-----------------+              +----------------+
  |  192.168.1.1/24 |              | 10.1 0.11.1/24 |
  |                 |              |                |
  |                 |              |                |
  | +---------------+--+        +--+--------------+ |
  | | 192.168.1.240/30 | <----> | 10.100.11.240/30| |
  | +---------------+--+        +--+--------------+ |
  |                 |              |                |
  |                 |              |                |
  +-----------------+              +----------------+

We mirror the whole thing, so that VPN clients can access the whole of the primary subnet.

install OpenBSD on the standalone machine
-----------------------------------------

After the initial installation, make sure you can install packages.

```Shell
su
fw_update
export PKG_PATH=http://mirrors.mit.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/
pkg_add -u
pkg_add vim htop
```

