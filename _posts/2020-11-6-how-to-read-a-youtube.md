---
layout: post
title: how to read a youtube
author: umhau
description: "because life is too short to watch them"
tags: 
- youtube-dl
- not offline yet
- sed
- linux
- do this with a music video
categories: walkthroughs
---
There's a video on youtube a friend of mine recommended I watch...but it's an hour long and that's _so long_. Be nice if I could just read / skim it instead. Cuts the involvement time down from an hour to maybe 10 minutes. Enter youtube-dl, closed captions, and some bad scripting.

If I download the closed captions of the video with youtube-dl
```bash
youtube-dl --write-auto-sub --skip-download <youtube-link-goes-here>
```
and then open them with something like nano, it's basically unreadable:

```
00:51:48.019 --> 00:51:48.029 align:start position:0%
distributed over a group of cells they


00:51:48.029 --> 00:51:49.819 align:start position:0%
distributed over a group of cells they
themselves<00:51:48.630><c> purely</c><00:51:48.989><c> at</c><00:51:49.259><c> the</c><00:51:49.380><c> electrical</c>

00:51:49.819 --> 00:51:49.829 align:start position:0%
themselves purely at the electrical


00:51:49.829 --> 00:51:51.229 align:start position:0%
themselves purely at the electrical
level<00:51:50.069><c> with</c><00:51:50.219><c> no</c><00:51:50.249><c> transcriptional</c><00:51:51.209><c> changes</c>

00:51:51.229 --> 00:51:51.239 align:start position:0%
level with no transcriptional changes
```
That example is from a video partially titled _Bioelectric Computation Outside the Nervous System_.  Interesting stuff, but long.

So, time to experiment with some line manipulation.  Let's grab just the captions, and make the filename something easy.
```bash
youtube-dl --output "captions.%(ext)s" --write-auto-sub --skip-download <video>
```
The name of the downloaded file is `captions.en.vtt`. Looks like the default language is english, hence the `en`. Let's start cutting down the noise.  
```bash
sed '/ --> /d' captions.en.vtt
```
This removes every line that's got the arrow in it. Check it out:
```
distributed over a group of cells they


distributed over a group of cells they
themselves<00:51:48.630><c> purely</c><00:51:48.989><c> at</c><00:51:49.259><c> the</c><00:51:49.380><c> electrical</c>

themselves purely at the electrical


themselves purely at the electrical
level<00:51:50.069><c> with</c><00:51:50.219><c> no</c><00:51:50.249><c> transcriptional</c><00:51:51.209><c> changes</c>

level with no transcriptional changes
```
Better.  There's still some weird stuff in there, and it looks superfluous.  The `<c>` string looks like it's always in those lines, so let's cut any line with one of those.
```bash
sed '/ --> /d' captions.en.vtt | sed '/<c>/d'
```
That's even better:
```
distributed over a group of cells they


distributed over a group of cells they

themselves purely at the electrical


themselves purely at the electrical

level with no transcriptional changes
```
But not finished yet. Tons of blank lines. 
```bash
sed '/ --> /d' captions.en.vtt | sed '/<c>/d' | sed '/^[[:space:]]*$/d'
```
Without the lines, this is what we get:
```
distributed over a group of cells they
distributed over a group of cells they
themselves purely at the electrical
themselves purely at the electrical
level with no transcriptional changes
```
Well, at least it's finally concise. Looks like each line is duplicated, though.  There's a cool linux tool that can find duplications - long as they're adjacent - and remove them. Often it's combined with `sort`, which can put similar or identical lines next to each other. In this case, we don't need that.
```bash
sed '/ --> /d' captions.en.vtt | sed '/<c>/d' | sed '/^[[:space:]]*$/d' | uniq 
```
We just want each line to be `uniq`.
```
distributed over a group of cells they
themselves purely at the electrical
level with no transcriptional changes
```
And we have it! The whole thing is going to read like some strange poem, especially since the closed captions will probably have made each line take about the same amount of time to say.  But, it's better than the alternative, where we take out all the remaining line breaks and it turns into a giant wall of text.

Putting the whole thing together into a script, we get this:

```bash
#!/bin/bash

link="$1"
fn="captions"

youtube-dl --output $fn.%(ext)s --write-auto-sub --skip-download $link

sed '/-->/d' $fn.en.vtt | sed '/<c>/d' | sed '/^[[:space:]]*$/d' | uniq > $fn.txt
```
