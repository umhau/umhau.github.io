This is a very manual process, that would likely only be more error-prone if it were wrapped up in a script; which means that instead, I'm documenting it in the blog.

I'm moving an organization from an ancient Microsoft DHCP server to OPNSense. I would set up an independent DHCP server, but for now the primary criteria is a) keep things running with minimum downtime and b) make sure other people can figure out how to use it (an OpenBSD default installation would be more ideal, but I really don't think it's a user-friendly choice).

So what I'm doing here is making sure that I'll remember how this works: export the reservations list off windows, get it onto my personal laptop, insert the relevant bits into an OPNSense backup file, and restore OPNSense from the doctored backup.

Oh - by the way, Windows DHCP doesn't include MAC addresses in the export, so we'll be getting those by scanning the network.

# 