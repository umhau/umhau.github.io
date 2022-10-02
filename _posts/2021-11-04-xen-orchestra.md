---
layout: post
title: Xen Orchestra
author: umhau
description: "compile the full version! because we're extra"
tags: 
- xen
- xen orchestra
- hypervisor
- virtualization
- xoa
- OS
- FreeBSD
categories: walkthroughs
---

So there's this thing about managing hypervisors: they're complicated. 

Not complicated in the sense that they're hard to conceptualize, but complicated in the sense that there's a lot you can do with them. Backups. Pause. Stop. Extra disks. Virtual networks. Incremental RAM backups. Migration between hosts. Host pools. And on, and on, _ad nauseum_. That means you need a lot of buttons and switches available, all organized nicely according to function, and available when you need them. It also means, behind the scenes, that you need to have written the code to do all those things. That's complicated.

Therefore, it makes a great moat if you want to start a business. Build a hypervisor management system, and make people pay for the complicated bits. But you don't call them 'complicated', you call them 'pro'. And you make darn sure they're the most interesting bits to work with. Fortunately, 'interesting' is closely related to 'complicated' in the demographic that cares about such things. 

That's where we are today. I want the 'pro' version of the hypervisor management system called "Xen Orchestra". The open source nature of the substrate it's built on necessitates that the source code of the pro version be freely available - but it does not require that the build system or the compiled binaries be available. So what we're doing today is compiling XO from source. And then installing it. And then setting it up.

Source: [official XOA walkthrough](https://xen-orchestra.com/docs/installation.html#freebsd).

operating systems, hypervisors, and the initial preparations
------------------------------------------------------------

Before we get to the code, we have to figure out where it's going. The XO hypervisor manager should be given its own virtual machine, on the hypervisor itself. I haven't hashed out exactly how the manager interfaces with the hypervisor, but I imagine it could live elsewhere without issue - similarly to XCP-ng Center. 

Create a new FreeBSD VM, and remember to include ports (I think that's important?). You don't need a whole lot of system resources, and I think it's even more solid than debian - plus, with how it manages updates, you can just update the same system without issue indefinitely, and never have to worry about migrating the system. 

There's anecdotes of people happily upgrading the same FreeBSD system from 2.0 up to present day - probably something around version 12 or so. (Put _that_ in Ubuntu's pipe and smoke it.) Perfect for a network where when I leave, the successors might not have the expertise to manage it -- that's not ideal, but it is pragmatic reality. If I can build things that never need to be touched, that's so much better.

Speaking of doing things the right way, decide if you want the web interface to run as root. If you're pragmatic and on a homelab network, it's probably fine. In fact, it seems like there's some extra complications inherent to the 'not-root' mode -- the system couldn't delete VMs, even though I'd done all the 'sudo' configs just as specified. Set up the whole thing as root, though, and the VMs delete just fine.  Just make sure that you enable ssh login as root. Otherwise...well, you'll figure it out sooner or later.

dependencies and configs
------------------------

As root, install packages and configure system. Note that 5GB is not enough for FreeBSD and XO.

```shell
su
freebsd-update fetch
freebsd-update install
pkg install vim tmux nano
pkg install gmake redis python git npm node autoconf yarn
npm update -g
pkg install jpeg-turbo optipng gifsicle
```

We want to use GCC instead of CLANG.

```shell
ln -s /usr/bin/clang++ /usr/local/bin/g++
```

Enable redis on boot, and start immediately.
```shell
echo 'redis_enable="YES"' >> /etc/rc.conf
service redis start
```

get the code, modify and build
------------------------------

Looks like we aren't totally free and clear when we use freebsd; the optional dependency `fsevents@1.2.13` failed the "compatibility check". Oh, well.  

```shell
git clone -b master http://github.com/vatesfr/xen-orchestra
```

There's a nag screen whenever you log into a built-from-source version of Xen Orchestra. It's very...nagging.  There's a [whole big discussion](https://xcp-ng.org/forum/topic/1815/nag-screens/30) about keeping it vs removing it, and both the developer and the (free-tier) user are reasonably civil throughout.  The upshot is, the devs need money and the user doesn't like being nagged, and getting sufficient income without the nag is uncertain.  However, we can still remove the nag if we feel like it. I rather do feel like it, because it does get in the way.

Go [here](https://github.com/vatesfr/xen-orchestra/issues/4175#issuecomment-488320434), [here](https://github.com/FoxieHazmat/xenorchestraSourceBannerFix/issues/1) and [here](https://github.com/megabert/xenorchestraSourceBannerFix) for sources. Open the `xen-orchestra/packages/xo-web/src/xo-app/index.js` file, and find the following two code fragments and delete them:

```shell
nano xen-orchestra/packages/xo-web/src/xo-app/index.js
```

```javascript
if (+process.env.XOA_PLAN === 5) {
    this.displayOpenSourceDisclaimer()
}
```

```javascript
{plan === 'Community' && !this.state.dismissedSourceBanner && (
    <div className='alert alert-danger mb-0'>
        <a
        href='https://xen-orchestra.com/#!/xoa?pk_campaign=xo_source_banner'
        rel='noopener noreferrer'
        target='_blank'
        >
        {_('disclaimerText3')}
        </a>
        <button className='close' onClick={this.dismissSourceBanner}>
        &times;
        </button>
    </div>
    )}
```

When you're done, make sure you're in the xen-orchestra directory and then build with yarn. Note, the last couple of commands take a while. Go get yourself a coffee while they run. (`&&` is excellent)

```shell
cd xen-orchestra
yarn
yarn build
```

Create and edit the configuration file for `xo-server`. There's the option to run the `xo-server` as a global service; since we're looking at running the whole thing as root, we might as well. 

```shell
cd packages/xo-server
mkdir -p /etc/xo-server
cp sample.config.toml /etc/xo-server/config.toml
```

Modify the config file to use a non-default port. Or not; it doesn't really matter. Default is 80, if you're feeling lazy.

```shell
vim /etc/xo-server/config.toml
```

<!-- The line you're looking for is super simple. But the default is fine.

```shell
port = 80
``` -->

runit
-----

If you've made it this far without major errors, you should be able to just start it. Go back to the directory where you got the config file, and from there you can launch.  After launch, go to the ip address of the machine, at the port you specified in the config file - if you did it right, the website should be there: right at `192.168.1.xxx:80`, or whatever. Login defaults are username: `admin@admin.net`, password: `admin`. 

```shell
cd ~/xen-orchestra/packages/xo-server
yarn start
```

Make sure the website starts when the VM boots. So much easier that way. We can just do it the old-fashioned way with cron.

```shell
crontab -e
# new entry: 
@reboot cd /root/xen-orchestra/packages/xo-server && yarn start &
```

The rest of the job is just setting yourself up with the new interface. I'll warn you, it's less intuitive than the Windows-only desktop program, Xcp-ng Center. I'm not going to provide any pointers about that interface, because if you need help figuring out the next few steps, you're going to be really, really stuck. 

Just make sure you have the login credentials to the root account of your hypervisor.
