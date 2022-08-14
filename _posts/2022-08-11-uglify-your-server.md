---
layout: post
title: Uglify Your Windows Server
author: umhau
description: "Pragmatics over Aesthetics"
tags: 
- Windows Server
- registry
- colors
- sysadmin
categories: walkthroughs
---

Sometimes I get confused. It's not much, very often; a misplaced coffee cup here, a bit of code forgotten there. But sometimes it's Important, and sometimes there's a chance to head the chaos off. This is one of those latter things. 

I have to administer some Windows Servers, and I'll often do that via remote desktop from my office computer. The problem is, windows is very good at making the experience seamless - which means that on two specific occasions, I've forgotten that I'm within the RDP session. I make a quick test, or (worse, much, worse) run a powershell command, and suddenly -- the wrong machine is newly different.

So what's the best way to solve human error? Blood. Red blood. 

Or, lacking that, blood red aesthetics: change the theme of the windows server to be all-red. That way, I'll never forget where I am. Problem is, you can't do that in Windows Server: 

![Just don't.](/images/windows/color_and_appearance.png)

So, we have to modify the registry directly. 

_(What's the registry? It's this giant, semi-centralized place where windows stores all the little miscellaneous bits of information that it needs to know about itself. One of those is, 'what-color-to-make-the-window-borders'.)_

```
regedit
```

Go to the subsection here:

```
HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM
```

Then `modify` the entry redundantly titled 

```
ColorizationColor
```

![Registry modification](/images/windows/server_2012_colorizationcolor_registry.png)

Colors are in HEX format, including alpha channel which is represented by c0. Go [here](http://hslpicker.com/#cd0404) to find a new color.

Note that the format includes transparency, so you have to modify the format a little bit, by sticking a `c0` to the front. In other words, the color `cd0404` you got from the color picker site becomes `c0cd0404`. Paste that into the registry entry, hit `Ok`, and you're all set. 

If you're using a remote desktop session, just quit and come back. If you're local, I think you can just log out and in again.

Behold the insanity:

![Horribleness](/images/windows/uglification.png)
