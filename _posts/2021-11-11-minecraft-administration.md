---
layout: post
title: Minecraft Administration
author: umhau
description: "automatic backups are a pain, yo"
tags: 
- minecraft
- rcon
- mcrcon
- tmux
- ssh
- fabric
categories: walkthroughs
---

I'm not proud of it. I'll deny it ever happened. It's my dark little secret and I buried the evidence.

That being said, I run a minecraft server.  It's shared with some friends, and we'll be modding soon.  That means I need to upgrade my backup game, and make it not-manual.  However, because minecraft likes getting commands in its own special console, doing things like turning-it-off and saving-game-state are more difficult than they ought to be. 

Not that there's an easy solution. 

So this is how I run the server. It's previously vanilla, now fabric. I'm self-hosting, though I might move over to digitalocean or something later on, if the performance mods are good enough (my buddies _love_ redstone, one of them went nuts with command blocks, and someone went and loaded most of the blocks in a 6k radius. Perf improvements are kinda necessary at this point). I'm also not going into the details of how I set up the server; that's a headache for a later day. Java is not fun to work with.

server config settings
----------------------

This is the `server.properties` file.

```Shell
#Minecraft server properties

# user-facing configs
server-port=55555
gamemode=survival
motd=Magic and Madness
difficulty=hard
max-players=10
view-distance=10
white-list=true

# world properties
spawn-protection=16
max-world-size=29999984
level-seed=

# constraints
enable-command-block=true
max-build-height=256
force-gamemode=false

# remote administration
enable-rcon=true
rcon.port=55556
rcon.password=password123

# other
query.port=25565
server-ip=
enable-query=false
generator-settings=
level-name=world
enable-jmx-monitoring=false
pvp=true
generate-structures=true
network-compression-threshold=256
max-tick-time=60000
require-resource-pack=false
use-native-transport=true
online-mode=true
enable-status=true
allow-flight=false
broadcast-rcon-to-ops=true
resource-pack-prompt=
allow-nether=true
sync-chunk-writes=true
op-permission-level=2
prevent-proxy-connections=false
resource-pack=
entity-broadcast-range-percentage=100
player-idle-timeout=0
rate-limit=0
hardcore=false
broadcast-console-to-ops=true
spawn-npcs=true
spawn-animals=true
snooper-enabled=true
function-permission-level=2
level-type=default
text-filtering-config=
spawn-monsters=true
enforce-whitelist=false
resource-pack-sha1=
```

If you want to use a whitelist, make sure you enable it after you've added yourself. 

start the server
----------------

Note that for some reason, the fabric server doesn't like being given the port number as a command line argument. You gotta put it in the `server.properties` file (see above).

```Shell
#!/bin/bash
# start-minecraft-fabric.sh

jarfile="/home/`whoami`/minecraft/fabric-server-launch.jar"
worldfolder="/home/`whoami`/minecraft/worlds/magic-and-madness/"

java -jar $jarfile --nogui --world "$worldfolder"
```

I often run this command inside a tmux session. Others use screen, or even a systemd service. Since we have a tool to interact directly, it doesn't really matter - so long as you don't use a naked session over ssh and then close it. That wouldn't work so well.

Do notice that after starting the server, you can enter commands right there where the log is scrolling past. I like using `/stop`.  It's apparently better than just `CTRL-C`.

stop the server
---------------

Notice that after you leave the tmux session where you launched the server, you no longer have any means to safely shut down the server. You have to go back into the tmux session and run `/stop` -- and how do you do _that_ from a script?  Enter `rcon`: did you notice it was enabled in the `server.properties` file above?

Download and install `mcrcon`, which is a special version just for minecraft. We'll use this to send arbitrary commands to our minecraft server, without ever having to reenter that tmux session.

```Shell
su -c 'apt update ; apt install git make gcc'
git clone https://github.com/Tiiffi/mcrcon.git
cd mcrcon
make
su -c 'make install'
```

For reference, here's the command line arguments available.

```
Option:
  -H            Server address (default: localhost)
  -P            Port (default: 25575)
  -p            Rcon password
  -t            Terminal mode
  -s            Silent mode
  -c            Disable colors
  -r            Output raw packets
  -w            Wait for specified duration (seconds) between each command (1 - 600s)
  -h            Print usage
  -v            Version information
```

Thus, given the settings given above; send three commands ("say", "save-all", "stop") and wait five seconds between the commands.

```Shell
mcrcon -H localhost -P 55556 -p password123 -w 5 "say Server is restarting!" "save-all" "stop"
```

backup the world files
----------------------

This is pretty straightforward. Everything we need to save is in the worldfile path, which we set as a variable in the start script. Just copy it somewhere, and you're good. If you have a problem and need to restore a backup, either copy it back or change that variable to point to the new location.

```Shell
mkdir -pv /home/`whoami`/backups/
cp -rv /home/`whoami`/minecraft/worlds/magic-and-madness/ /home/`whoami`/backups/worldfile.`date +"%m_%d_%Y"`.bak
```

If we want to store the backups elsewhere, we can use `scp` to push them to some other server. First, though, we have to make sure we can log into that server without a password prompt.  Then we can do a direct copy to the other server.

```Shell
# remote server login info
ipaddress='200.200.200.200'
portnum='12345'
username='rando'

# set up passwordless login
ssh-keygen
ssh-copy-id -p $portnum $username@$ipaddress

# do a copy
scp -r -P $portnum /home/`whoami`/minecraft/worlds/magic-and-madness $username@$ipaddress:backups/minecraft/worldfile.`date +"%m_%d_%Y"`.bak
```

automatic backups (a.k.a. putting it all together)
--------------------------------------------------

Simplest way to do it: make a script that stops the server and backs it up. Then either have the same script restart it, or just wait N minutes and have another script turn it back on.

```Shell
#!/bin/bash
# backup-minecraft-world.sh

# stop the server & save the latest copy of the world to file
mcrcon -H localhost -P 55556 -p password123 -w 5 "say WARNING: server is restarting in 10 seconds" "save-all" "stop"

# wait until it's done stopping
while pgrep "java" >/dev/null 2>&1 ; do sleep 1 ; done

# copy the worldfile to the offsite backup
ipaddress='200.200.200.200'
portnum='12345'
username='rando'
scp -r -P $portnum /home/`whoami`/minecraft/worlds/magic-and-madness $username@$ipaddress:backups/minecraft/worldfile.`date +"%m_%d_%Y"`.bak

# start the server again, and fork it
jarfile='/home/`whoami`/minecraft/fabric-server-launch.jar'
worldfolder='/home/`whoami`/minecraft/worlds/magic-and-madness/'

java -jar $jarfile --nogui --world "$worldfolder" &
```

You can put this in a cronjob so it runs nightly, or weekly. First, install the file somewhere.

```Shell
su -c 'install ./backup-minecraft-world.sh /usr/local/bin/'
crontab -e
```

Here, we're running the backup every day at 4AM. Hopefully no one's online then. If they are, they probably shouldn't be. Notice the `su` weirdness, BTW. If you set up the cron while a 

Also, this is running as the default (not-root) user. That way it has access to the ssh key you generated. 

```Shell
0 4 * * * backup-minecraft-world.sh
```

On the other server, you can make some fancy script to delete some subset of the backups, or you can just do it manually every month or two. Though, some math would be in order: if the world files are 3GB, after a month you'll have used a whopping 90GB...lol.

Have fun!

P.S. I haven't tested this yet, _at all_. Almost everything is based on my bad memory; I'm not standing behind this post until this disclaimer is removed.  In particular, I can't remember if the ssh key needs to be explicitly added as an argument to the scp command, if we're using cron. I think it might need to be.
