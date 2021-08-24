---
layout: post
title: vegan dieselpunk
author: umhau
description: "An exploration into cheap electricity"
tags: 
- diesel
- electricity
- vegetables
- AC/DC
- engines
- power
categories: other
---




Which means a building to house the generator installation will probably be a good idea. 

![generator installation](/images/diesel/generator_installation.png)

There's a few different ways this could be set up.  Each of them involve a diesel engine, like this one I found on Craigslist: 

![diesel engine](/images/diesel/engine.jpg)

### Motor -> AC Generator

This is the best version for constant, high load. The engine is connected directly to the generator, and the generator creates AC current at whatever frequency the engine drives it at: which means you have to run the engine at a specific speed in order to make 60Hz household current.  This is an example; in the second image, you can see where you can hook it into your wiring system; it can provide a full 240 Volts at the proper 60Hz, if operated correctly. It's called a "Single-Phase AC Syncronous Generator."

![generator](/images/diesel/generator.jpg) ![generator 2](/images/diesel/generator_2.jpg)

The downside is obvious: if you can't run your generator at a consistent 1800 rpm, then you'll fry the electronics hooked into the electricity it's producing. Not great. Plus, what if you don't need a whole lot of power right now? Tough luck - you can't idle the engine, or the power won't be at the right frequency and you won't be able to use it for anything.

### Motor -> DC Generator -> Inverter

That's where inverter-generators come in: generate whatever sort of dirty AC weird-frequency power you like (at whatever engine speed is convenient), convert it to clean DC, then convert it _back_ into clean AC. You lose efficiency at each conversion, but you don't have to waste energy (and noise) running the generator at full tilt all the time. This is what most [small portable generators](https://www.harborfreight.com/generators-engines/generators/inverter-generators.html) are - the little things you can take camping. 

Trouble is, I'm not totally sure how to construct one of these from the constituent pieces - the one place I found so far that describes a DIY approach gave opaque instructions that seemed to be asking me to build the AC->DC component from scratch.  I think a car alternator performs that function; but it also sounds like a [truck alternator](http://www.delcoremy.com/alternators/find-by-model-family/36si) would be designed for the higher amperage I'm aiming for. 

    170 Amps x 12 Volts         = 2040 Watts
    2040 Watts x 72% Efficiency = 1468 Watts
    1468 Watts / 120 Volts      = 12.24 Amps

...and that, ladies and gents, is why we don't use vehicle alternators in our DIY inverter-generators.  12 Amps is not even close to enough - we should be getting closer to 9500 Watts output, which would give us (if that's a post-efficiency-loss number):

    9500 Watts / 120 Volts = 79.16 Amps

So, the question becomes how to source an alternator. 

### Indirect with alternator & batteries


