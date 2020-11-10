---
layout: post
title: find stuff fast (ish)
author: umhau
description: "easy (ish) to remember, and very effective"
tags: 
- command line
- find
- grep
- linux
- not windows
- good luck on iOS
categories: memos
---

I ran into this command combo once, when I was digging through the `~/.bash_history` of a FreePBX Asterisk server I'd inherited. Some of the IP phones connected to it, weren't, and I'd already pulled that [evil maid attack](https://umhau.github.io/the-evil-maids-basic-attack/) in order to wrest access to that server. Nobody had bothered to write down the root password, except maybe the vendor that set it up about 15 years prior. Or, specifically, the one guy that had run point with my organization. Except that he was dead. 

So after I gave myself access to that particular box, I went rooting through the aforesaid bash history trying to see what exactly Asterisk was, where the files were, how it was installed, and where the phones were configured. Spoiler: it took me 12 hours to solve that one, but I did solve it. While in that bash history, I came across this command. It stuck with me, not because it was elegant (it's not), but because it's so obvious, and so easy to remember.

I don't remember what the previous dude was looking for, but it was a situation where there's a file _somewhere_ on the system, buried in any number of layers of `/opt/usr/local/bin/local/tryagain/` system folders.

```
find / . | grep "search term"
```

That's it. You have `find` spit out the path of every file on the system in succession, and then have `grep` check each one for a match. It'll return a list of file paths matching the search term.

However, be careful: as-is, this will enumerate everything that the system can see. That might include some distant, high-latency, freeze-your-system-while-you-wait NFS mounts. If you can, replace the `/` with a more targeted initial search directory.
