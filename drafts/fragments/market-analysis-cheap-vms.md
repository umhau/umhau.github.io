When I say "cheap", I mean _cheap_: 1 USD per month per VM, maybe even $0.50, charged per month (or even per-day? that would hit sub-cent pricing though, so not practical without either using satoshis or credits).  For that price, there's some limitations: 

- shared cores limit the speed to an effective 100 MHz
- Spectre (etc.) type attacks are totally possible (unless the sheer number of concurrent VMs makes cache speculation impossible, since processes would be changing rapidly and randomly - nothing would stay still long enough to get a useful result)
- dedicated IPV4 addresses are out of the question: possibly a shared IPV4 via ports, but more likely a dedicated IPV6 address

I think the storage can be reasonable, 1-5 GB.

What's the value of such a machine?

- DIY VPN
- gateway for external connections to an internal network on a fluctuating or residential IP address
- webhost for a static site
- git repo
- anonymous server (purchase with crypto)
- IRC server host
- IRC client host
- DNS resolver
- IP address synchronization between changing nodes (small home network, or large meshnet)

Note that because I'm making such a list, I don't have a specific pain point in mind. However, that being said, I have noticed that no one has attempted to sell dollar-store virtual machines, and I would chalk it up to the demographic making these products (skews heavily towards nerds, and away from anyone who might have learned marketing), rather than any real problems associated with selling it that cheaply. And if there are such problems, I'd bet I can find acceptable trade-offs.


needs ipv4 support, even though only ipv6 likely to be provided
https://github.com/toreanderson/clatd