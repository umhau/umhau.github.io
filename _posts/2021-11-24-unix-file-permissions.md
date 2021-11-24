---
layout: post
title: Set Permissions, don't grant Forgiveness
author: umhau
description: "unix file permissions"
tags: 
- UNIX
- permissions
- chmod
- chown
- root
categories: memos
---

File permissions. Can't live with em, can't live without em.  Personally, I never got the hang of them. Just memorized a couple quick tricks and moved on.

```sh
# use `sudo` to make a script executable, and put it somewhere on the `$PATH`:
sudo install script.sh /usr/local/bin/

# The permission code '777' lets anyone do anything.
sudo chmod 777 file.txt

# Use `root` for everything! The world is your oyster.
su root

# Change the owner to yourself:
sudo chmod `whoami`:`whoami` file.txt
```

These are nice, but still just a (very crude) band-aid. I'm working on a webserver project, so it's time to figure this stuff out properly - there's actual consequences if I don't.

UNIX file permissions
---------------------

Something before we start. "Groups" are this secondary concept associated with "users". It's like a tag: if your user is part of a certain _group_, then you get extra permissions to do certain things.  For instance, if you're in the _wheel_ group, then you're allowed to use `su` to login as root. There's also a 'printers' group, at least in some systems: presumably, being part of that group lets you print things.  Okay? Ok.

The folks who built what we know as UNIX (or, maybe, we don't know it as UNIX. IDK.) were thrifty in their bit budgets.  They found a way to compress 9 separate, related configs into 3 digits associated with each file and folder. How and why? There's three categories of users who might have some kind of permission, and three categories of permission types. Together, there's 9 different possible combinations (or is it permutations?) of those two groups of three. See below:

|           | File Owner    | File Owner's Group | Anyone Else |
| ----------|:-------------:|:------------------:|------------:|
| *read*    | 4             | 4                  | 4           |
| *write*   | 2             | 2                  | 2           |
| *execute* | 1             | 1                  | 1           |

Probably wondering what the cryptic numbers are. If you're clever with numbers, you might notice that if you sum some combination of 4, 2 and 1, you'll always be able to tell which ones you combined - if the sum is 7, it's all three; if 6, 4 and 2; if 5, 4 and 1, and so on. This means we can use one digit to represent the read, write, and execute permissions simultaneously, for either the file owner, file owner's group, or anyone else. 

Thus, if a file has permissions 777, that means it has `4+2+1=7` permissions for all three sets of possible people. If it has permissions 600, we can translate that, too: 

```
600
6          , 0    , 0
4+2        , 0    , 0
read+write , none , none
```

And we know that the three columns are: file owner, file owner's group, and anyone else; so now we know that no one can execute a 600 file, and only the owner can read or write it.  
