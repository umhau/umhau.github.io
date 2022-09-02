My company needs a vpn. There's easy ways to do this, and there's hard ways to do this; and there's middling ways that actually get the job done while remaining scrutable to those who come after.

There's just one complication: whoever set this network up originally thought it'd be a great idea to just use old faithful for the ip address range - 192.168.1.1/24. If you don't yet see what the problem is, imagine the situation from the perspective of a laptop on a basic home network connected to the vpn. Where is the machine with ip address 192.168.1.1 physically located? What's wrong with that question?

To solve that little problem, we're going to take the following steps.

- First we build a standalone box running OpenBSD with at least two ethernet ports (a third can give us backup access to the box if something goes wrong).

Why a standalone box? Because there's all kinds of extra hijinks the layer of abstraction makes us vulnerable to. Hypervisors are awesome, and I'll use them for most things, but in the immortal words of Theo de Raadt:

> You are absolutely deluded, if not stupid, if you think that a worldwide collection of software engineers who can't write operating systems or applications without security holes, can then turn around and suddenly write virtualization layers without security holes.

This is an extreme take on security, but appropriate for our VPN. We use Theo's OS because network configuration is rediculously painless, and because he's such a stickler for security.

- Connect one port on the machine to the outside network, and one to the internal network.
- Set up 