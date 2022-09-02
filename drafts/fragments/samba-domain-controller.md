https://www.turnkeylinux.org/domain-controller

> Please note that Samba4 is not compatible with the latest Windows Server AD Schema. This should not be a problem if all your Domain Controllers use Samba. However, if you wish to join to an existing AD domain, please check the Windows AD schema to confirm it is compatible with Samba. TurnKey Linux uses the version of Samba packaged by Debian. In v16.x that is 4.9 and in v17.x will be 4.13.

> Windows 2008R2 AD schema (or below) should be supported out of the box (although there may be some 2008R2 related edge case bugs still apparent in v16.x). However, you may be able to upgrade to Windows Server 2012 AD schema support (should be possible in TurnKey v17.x - unconfirmed in v16.x) or perhaps even higher (requires specific workaround).