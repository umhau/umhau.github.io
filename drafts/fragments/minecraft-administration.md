I'm not proud of it. I'll deny it ever happened. It's my dark little secret and I buried the evidence.

That being said, I run a minecraft server with some friends, and we're going to be modding soon.  That means I need to upgrade my backup game, and make it not-manual.  However, because minecraft likes getting commands in its own special console, doing things like turning-it-off and saving-game-state are more difficult than they ought to be. 

Not that there's an easy solution. 

So this is how I run the server. It's previously vanilla, now fabric. I'm self-hosting, though I might move over to digitalocean or something later on.

start the server
----------------

Note that for some reason, the fabric server doesn't like being given the port number as a command line argument. You gotta put it in the `server.properties` file.

```Shell
#!/bin/bash

jarfile='fabric-server-launch.jar'
portnumber='55555'
worldfolder='worlds/magic-and-madness/'

java -jar $jarfile --nogui --world "$worldfolder"
```

