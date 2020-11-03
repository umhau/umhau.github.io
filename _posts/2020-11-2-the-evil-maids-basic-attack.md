---
layout: post
title: the evil maid's basic attack
author: umhau
description: "in case you forgot all the passwords"
tags: 
- chroot
- live disk
- passwd
categories: walkthroughs
---

So I've been working with hypervisors recently.  I have a single primary server, let's call it _bob_; there's about 4-5 VMs on it right now that are fairly important.  The feasibility of replacing them ranges from trivial to that'll-cost-you; the size of the VMs and the fact that that server represents most of my HDD space means that if I wanted to just copy them somewhere else, there's nowhere to put them. 

So of course, I lost the root password.

This is the saga of how I broke into my server and replaced it.

Step 1: make a live usb. Probably doesn't matter a whole lot what it actually is; I used Ubuntu 20.04 Desktop. Just so long as it gives you the basic command line utilities...though the way Ubuntu is heading, I wonder how long it'll still have those.  Boot the server from the live USB.

Figure out where the HDD is that's got the root filesystem of the hypervisor, and mount it.  Surprisingly, this was easy to do with the Files program Ubuntu provided. Point in its favor.  If it's easier, just right click and open in terminal.  If you're having trouble figuring out which drive you're looking for, just remember that there's going to be a lot of folders that look like 'usr' 'bin' 'root' 'etc', etc.

Open a terminal, and switch to root.

```
sudo su root
```

Once you're in a terminal, and you're inside the mounted drive, make sure you're in the right place. If you run the 

```
pwd
```

command, it should tell you where you are in the folder structure. It should be something like 
```
/media/lvmdrive21/
```
but it could vary. As above, check what the other folders in that directory look like to make sure you're in the right place.  You want to be in the _root directory_ of the busted server; that's really important and if you don't get that right then nothing will work and you're going to feel really bad.  

Now you're ready for the fun stuff.  Note that as of this moment you have total root access to the data contained in the victim computer; you can do whatever you want, and I'm just pointing out one little nasty thing that could be done. 

```
chroot .
```

This command _changes root_ so that after you run it, the shell you're in uses the given directory as the root of the file system. (this is also the basic paradigm behind docker files; if you're thinking that that seems really simple for all the craziness docker introduces, you're right - docker only really came into its own after it tacked on a ton of bells and whistles. If you don't know who docker is or why they like bells, I don't think you're missing much.)

Now you can run commands and the shell will look inside the filesystem of the _victim's drive_ for the wherewithall to execute them.  So, for instance, now you can run 

```
cat /etc/passwd
```

and instead of listing the users on your live usb (not that many there), it'll list the users on the victim's drive.  Let's back that file up, and /etc/shadow, which is where the verification hashes for the user passwords go.  

```
cp /etc/passwd /root/
cp /etc/shadow /root/
```

Can you guess what happens next? Time to change the root password.

```
passwd root
```

That will change the password of the root account, and you're officially an evil maid!

Reboot and log back into your hypervisor like nothing's happened. 