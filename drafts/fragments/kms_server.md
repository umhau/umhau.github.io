


Ever tried to manage active directory? It's not fun, especially when you're used to the (relatively) frictionless experience of BSD and Linux.  Turns out there's this cool system called SAMBA, which serves as an open-source version of Active Directory, and can actually do user authentication.  

I'm considering using it - far as I can tell, it's a way to get around the onerous user licensing scheme used by recent Windows Server editions.  Hopefully, it'll be able to run automatic backups indefinitely, and become another 'just works' appliance in the background. Especially if I can use FreeBSD - then it could plausibly last 10+ years without anyone needing to touch it.

But that's not why I'm here. And it's not why you're here, either.  I'm trying to set up Office 2019, and it requires a local KMS host. I was really hoping to not have to keep a windows server on the premises anymore, so I went looking for an open-source variation. Sadly, SAMBA doesn't do KMS hosts; so I found something else.

And that's why we're here. Because it's not just 'something else' -- it's a standalone Microsoft office authentication server, batteries included, wheels on the ground, no strings attached. Turns out, Microsoft was a little too confident that their KMS binary wouldn't be reverse-engineered. Or, at least, that's what I understand so far. Seems like the most charitable interpretation on both sides is, that the KMS host architecture wasn't built quite right, and the best way to reverse-engineer an open-source version of it also happened to obviate the need to purchase unique license keys.

Which is annoying, because it would be really nice to avoid using Windows servers in the backend of professional environments, but there's no other way I've found to run a KMS host that isn't Windows. We could just buy the keys and not use them, but that still seems...sketchy.

KMS host - Microsoft-approved version
-------------------------------------

    Install-WindowsFeature -Name VolumeActivation -IncludeManagementTools
    Set-NetFirewallRule -Name SPPSVC-In-TCP -Profile Domain,Private -Enabled True
    
    https://gist.github.com/jerodg/502bd80a715347662e79af526c98f187

KMS host - good engineering version
-----------------------------------

Download and install. https://github.com/Wind4/vlmcsd
