So there's this thing about managing hypervisors: they're complicated. 

Not complicated in the sense that they're hard to conceptualize, but complicated in the sense that there's a lot you can do with them. That means you need a lot of buttons and switches available, all organized nicely according to function, and available when you need them. It also means, behind the scenes, that you need to have written the code to do all those things. That's complicated.

Therefore, it makes a great moat if you want to start a business. Build a hypervisor management system, and make people pay for the complicated bits. But you don't call them 'complicated', you call them 'pro'. And you make darn sure they're the most interesting bits to work with (fortunately, 'interesting' is closely corellated with 'complicated' in the demographic that cares about such things). 

That's where we are today. I want the 'pro' version of the hypervisor management system called "Xen Orchestra". The open source nature of the substrate it's built on necessitates that the source code of the pro version be freely available - but it does not require that the build system or the compiled binaries be available. So what we're doing today is compiling XO from source. And then installing it. And then setting it up.

sources
-------

- [Official XOA Walkthrough](https://xen-orchestra.com/docs/installation.html#freebsd)

operating systems, hypervisors, and the initial preparations
------------------------------------------------------------

Before we get to the code, we have to figure out where it's going. The XO hypervisor manager should be given its own virtual machine, on the hypervisor itself. I haven't hashed out exactly how the manager interfaces with the hypervisor, but I imagine it could live elsewhere without issue - similarly to XCP-ng Center. 

1. Create a new FreeBSD VM, and remember to include ports (I think that's important?). You don't need a whole lot of system resources, and I think it's even more solid than debian - plus, with how it manages updates, you can just update the same system without issue indefinitely. (There's anecdotes of people happily upgrading the same FreeBSD system from 2.0 up to present day - something around version 13.0. Put _that_ in Ubuntu's pipe and smoke it.)

2. Decide if you want the web interface to run as root. If you're pragmatic and on a homelab network, it's probably fine. If you're not, might be a good idea to create a separate user.  Create the user during installation, and afterwards give them permission to use `sudo`.  I'll assume the user is `xoa`, and that all the following commands are performed as the `root` user.

```Shell
pkg install vim tmux nano
pkg install sudo
pw usermod xoa -G wheel
visudo
# find and uncomment this line:
# %wheel ALL=(ALL) ALL
reboot
su xoa
sudo ls # make sure it works
```

Dependencies and configs
------------------------

3. Install packages and configure system. Again, as root, unless specified otherwise.

```Shell
freebsd-update fetch
freebsd-update install
pkg install gmake redis python git npm node autoconf yarn sudo
npm update -g
pkg install jpeg-turbo optipng gifsicle
```

We want to use GCC instead of CLANG.

```Shell
ln -s /usr/bin/clang++ /usr/local/bin/g++
```

Enable redis on boot, and start immediately.
```Shell
echo 'redis_enable="YES"' >> /etc/rc.conf
service redis start
```

get the code
------------

4. Do this as your non-root user, so it ends up with the correct permissions.  Looks like we aren't totally free and clear when we use freebsd; the optional dependency `fsevents@1.2.13` failed the "compatibility check". Oh, well.

```Shell
git clone -b master http://github.com/vatesfr/xen-orchestra
cd xen-orchestra
yarn
yarn build
```

5. Create and edit the configuration file for `xo-server`. There's the option to run the `xo-server` as a global service; I don't know if that's desirable, but it requires that the config file go in a global location instead of the home directory.

```Shell
cd packages/xo-server
mkdir -p ~/.config/xo-server
cp sample.config.toml ~/.config/xo-server/config.toml
```

6. Modify the file, and set the default port to something higher than 1024, since we're not running as root. I'm using 1100, because idk. Also enable the use of sudo. Do this by setting `useSudo = true`. 

```Shell
# change port number and useSudo
vim ~/.config/xo-server/config.toml

sudo visudo
# then add this line to the bottom:
username ALL=(root)NOPASSWD: /bin/mount, /bin/umount
```

runit
-----

7. If you've made it this far without major errors, you should be able to just start it. Go back to the directory where you got the config file, and from there you can launch. Again, do this as the not-root.

```Shell
cd ~/xen-orchestra/packages/xo-server
yarn start
```

8. Make sure the website starts when the VM boots. The `forever-service` isn't available for FreeBSD, so we can just do it the old-fashioned way with cron. Do this as not-root.

```Shell
crontab -e
# new entry: 
@reboot cd /home/xoa/xen-orchestra/packages/xo-server && yarn start &
```

bugs
====

There's some permission denied errors given by yarn when I run the website. I wonder if it can be resolved if I run as root.

```Shell
xoa@xo:~/xen-orchestra/packages/xo-server $ yarn start > ~/log.txt
2021-11-04T20:28:24.897Z xo:mixins:hooks WARN start failure {
  error: Error: spawn losetup ENOENT
      at Process.ChildProcess._handle.onexit (node:internal/child_process:282:19)
      at onErrorNT (node:internal/child_process:477:16)
      at processTicksAndRejections (node:internal/process/task_queues:83:21) {
    errno: -2,
    code: 'ENOENT',
    syscall: 'spawn losetup',
    path: 'losetup',
    spawnargs: [ '-D' ],
    originalMessage: 'spawn losetup ENOENT',
    shortMessage: 'Command failed with ENOENT: losetup -D\nspawn losetup ENOENT',
    command: 'losetup -D',
    escapedCommand: 'losetup -D',
    exitCode: undefined,
    signal: undefined,
    signalDescription: undefined,
    stdout: '',
    stderr: '',
    failed: true,
    timedOut: false,
    isCanceled: false,
    killed: false
  }
}
2021-11-04T20:28:24.904Z xo:mixins:hooks WARN start failure {
  error: [Error: EACCES: permission denied, mkdir '/var/lib'] {
    errno: -13,
    code: 'EACCES',
    syscall: 'mkdir',
    path: '/var/lib'
  }
}
2021-11-04T20:28:24.905Z xo:mixins:hooks WARN start failure {
  error: [Error: EACCES: permission denied, mkdir '/var/lib'] {
    errno: -13,
    code: 'EACCES',
    syscall: 'mkdir',
    path: '/var/lib'
  }
}
2021-11-04T20:28:24.905Z xo:mixins:hooks WARN start failure {
  error: [Error: EACCES: permission denied, mkdir '/var/lib'] {
    errno: -13,
    code: 'EACCES',
    syscall: 'mkdir',
    path: '/var/lib'
  }
}
2021-11-04T20:28:24.906Z xo:mixins:hooks WARN start failure {
  error: [Error: EACCES: permission denied, mkdir '/var/lib'] {
    errno: -13,
    code: 'EACCES',
    syscall: 'mkdir',
    path: '/var/lib'
  }
}
2021-11-04T20:28:24.907Z xo:mixins:hooks WARN start failure {
  error: [Error: EACCES: permission denied, mkdir '/var/lib'] {
    errno: -13,
    code: 'EACCES',
    syscall: 'mkdir',
    path: '/var/lib'
  }
}
2021-11-04T20:28:24.907Z xo:mixins:hooks WARN start failure {
  error: [Error: EACCES: permission denied, mkdir '/var/lib'] {
    errno: -13,
    code: 'EACCES',
    syscall: 'mkdir',
    path: '/var/lib'
  }
}
2021-11-04T20:28:24.985Z xo:mixins:hooks WARN clean failure {
  error: [Error: EACCES: permission denied, mkdir '/var/lib'] {
    errno: -13,
    code: 'EACCES',
    syscall: 'mkdir',
    path: '/var/lib'
  }
}

```