One of the joys of sysadmining is the endless windows installations. You can't get away from it - Windows is everywhere. It creeps into your life and holds on. Like a virus. You just can't get rid of it! First it's just a Word doc someone emailed you, but that quickly morphs into a Windows VM, hosting a growing number of windows-only apps and 'productivity' tools - and from there it's a short hop to a full blown windows installation. And at that point, it's too late: you'll have to build your entire selfhosted homelab around the needs of that box. Want to share files? Sorry, NFS or SSHFS is a no-go. You're using samba now. And the insanity mounts.

But the trouble is setting up those windows installations with some semblance of determinisim and automation. If we were on linux, we could autobuild and modify filesystems all day - drop config files wherever they're needed, boot them in VMs or containers for testing, and just generally do whatever we want. Barely needs any infrastructure, either. Most of the tools you need are already installed, and you probably use them anyway. When was the last time you `mounted` a disk (image), or `cp'd` a file?

Over in Windows World, they really don't like making your life easy. So when our windows disk image failed to boot on a new machine, do you know what the error message was? "Windows Failed to Boot." With some logical deduction and way too much tedium, I worked out that the motherboard was new enough that windows didn't have the drivers to see the local hard drives - so as soon as the BIOS passed the ball to Windows, Windows dropped it. 

So now we have to install drivers onto a windows installation that we can't boot. 

## diskpart

Note: we're assuming you're doing this from windows. It _might_ be possible to do something like this in linux, but that may or may not involve some custom bash scripts. 

Open powershell as admin. You'll need it. 

Then use the diskpart utility to figure out the drive letter assigned to the partition with the windows installation you want to modify. 

```powershell
diskpart
list disk
```

See if you can guess from the size which number is the disk you attached. When you're done, get out of there.

```powershell
select disk 1
list volume
exit
```

## Deployment Image Servicing and Management (DISM)

Do you remember where the driver is? Go find it. 

Drivers in windows are weird. Before I really thought about them, I just assumed they were a binary blob that got 'installed' into windows - maybe there was a folder or something in `C:\Windows` where they went. Turns out they're a bit more sophisticated than that - you have an entire folder dedicated to a single driver, and the file you care about is `drivername.inf`. This isn't a blob: it's a manifest. It lists the actual blobs, which are also in the folder, and says where to put them, and, crucially, how to tell windows about them. Which means registry entries. 

So it's theoretically possible to parse and modify manually, as long as there's an agnostic mechanism for manipulating a registry on an external disk. I really hope that's some kind of database of a standard type - maybe even ascii instead of binary - in a distinct file. But knowing Microsoft's penchant for complexity, I really doubt it. It'd be too easy to work with, and those Microsoft Certified Professional Expert Consultants (TM) need to eat.

We're just gonna say that you dropped the driver file in `D:\z680\disk\Drivers\RAID\Driver\64bit`.

We're also gonna say that you attached the drive with the windows installation to your machine, and the Windows OS partition on that drive is `G:`.

With that said, we can just go ahead and install the driver. 

```powershell
dism /image:G:\ /add-driver /driver:D:\z680\disk\Drivers\RAID\Driver\64bit /recurse
```

Safely remove, reattach the disk to the machine, and boot.
