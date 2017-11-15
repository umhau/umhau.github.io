---
layout: post
title: command line alarm clock
author: umhau
tags: 
 - CLI 
 - linux 
 - alarm clock 
 - bash
 - don't sleep in
 - Ubuntu Server 17.10
 - i3
categories: tools
---

A quick script that plays a song after a chosen interval (I like that better than a set time). 

```bash
#!/bin/bash

key=' '; song="/path/to/music/file.mp3"; 

if [ ! -z "$1" ]; then echo -n "confirm: $1 hrs until wakeup (press enter)"; read; h=$1; else h='8'; fi
wt=$(date -d "today + $h hours + 15 minutes" +'%H:%M'); echo -n "alarm will sound at $wt"; 
for i in 1 2 3 4 5; do sleep 1; echo -n ". "; done; sleep "$h"h 15m 

{ amixer set Speaker unmute; amixer set Master unmute; amixer set Master 100%; amixer set Speaker 100%; } &> /dev/null

echo; date; { mplayer -loop 0 $song & } &> /dev/null; pid=$!
while IFS="" read -n1 char ; do
 if [ "$char" = "$key" ] ; then kill "$pid"; echo -e "\n"; break; fi
done
```

This should cover the basic sanity checks - ensure the volume is up and unmuted, make the wakeup time obvious, give a few extra minutes of margin, and be super simple to use when tired.

Save the preceeding code into a file called 'wakeup' (I don't use file extension). Let's pretend you save the file into your Documents folder.  Use the following line of code to install it.  (Also: choose a music file and put the location instead of the dummy location I've got at the top of the script)

    sudo cp /home/`whoami`/Documents/wakeup /usr/local/bin/wakeup; sudo chmod +x /usr/local/bin/wakeup

Now that's done, you can open a new terminal instance and type 

    wakeup

and the computer will wake you up with whatever song you chose.  Press the space bar to turn it off.  [Here's](https://www.youtube.com/watch?v=McdMwOV0y6c) a good one, by the way.  You'll see what I mean. 

### sources

* https://askubuntu.com/questions/164289/how-to-play-a-song-on-mplayer-on-repeat
* https://stackoverflow.com/questions/29343245/execute-a-command-in-a-script-and-kill-it-when-pressing-a-key
* https://stackoverflow.com/questions/28800740/how-to-read-a-space-in-bash-read-will-not
