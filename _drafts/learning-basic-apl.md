---
layout: post
title: Learning basic APL
author: umhau
description: ""
tags:
- APL
- cheat sheet
---

The commands to start apl and stop apl are
    apl
    )OFF

apl scripting
-------------

script header - this use of an apl script preserves its continuity with the apl environment.
    #! /usr/local/bin/apl --id 1010

an alternative header forces the apl script to run independently, without (for example) starting a thread to monitor global variables.  With this header, the script should be made executable and should not be called with the apl command.
    #! /usr/local/bin/apl --script

With these two header types, there are also two methods for starting an apl script.  the first uses the shell to redirect the script into APL, while the second uses APL to redirect the script.

    apl < SCRIPT.apl
    apl -f SCRIPT.apl




sources
-------

- https://www.gnu.org/software/apl/apl.html#Starting-APL
