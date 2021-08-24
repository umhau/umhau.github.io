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

Crypto mining is apparently getting pretty big, and apparently GPU crypto mining is still a thing these days. The cool part is how it's become an arbitrage (big word...am I using it right?) to convert electricity into dollarinos.  Since I have some space, and my neighbors aren't likely to be bothered by noise pollution, I think it could be valuable to find the cheapest (legal) source of electricity I can.  

Considered options:

### Thermal power

Based on the difference between static ground temp and the outside temp, doesn't seem super practical: dig a horizontal hole, feel the gentle breeze as the air temperature evens out, and then rig a fan to spin with that breeze. Hey - give it a week, you might charge your phone!

### Gravity

(Gravity mechanism: manually hang a weight in the air, attach a generator to the other end; weight slowly falls, generator spins, electricity comes out.) Gravity-based mechanisms are apparently very inefficient. 

    100 kg x 9.8 m/s^2 gravity force x 10 meters = 9.8kJ = 2.72 Watt-hours
    1 AA Battery = 3 Watt-hours

A 100kg weight falling 10 meters generates about the energy equivalent of a AA battery -- so not super great. I don't feel like hoisting a couple of tons of rock into the air just to charge my laptop.

### Wind

This gets into tricky regulations, and even more feasibility constraints. There might be limits on whether I can legally put up a tower, and I'm not sure there's a lot of wind where I am.  Plus, those towers are expensive.

### Solar

These are better than I guessed at first. That being said, I don't have access to a lot of sunlit square footage. Secondly, new solar panels are also _expensive_.  Third, you have to set up not just the solar panels, but enough batteries to [survive the darkness](https://www.imdb.com/title/tt0134847/).  

Craigslist is a great source of panels, however. I found these for an ask of $80:

![Solar panels](/images/diesel/solar_panels.jpg)

They produce 100 Watts each. If you recall your electrical engineering, that means at perfect efficiency:

    (100 Watts x 2 panels) / 120 Volts = 1.66 Amps

And, of course, that's on a devestatingly sunny day with a physics-defying DC->AC inverter.  Expect much less than that; possibly, those two panels would get you a reliable 1 Amp on a sunny day.  Now consider that a standard household circuit has a fuse limit of (probably) 20 Amps, and a microwave draws 9-15 Amps.  A refrigerator uses another 7 Amps. Your laptop probably uses another 5 Amps (...ish). A portable AC unit takes another 5 Amps, and a Central AC unit might take a whole 15-20 Amps.   

So far, we're up to `9 + 7 + 5 + 5`, conservatively.  That's 26 Amps total, and 52 (fifty-two!) of those solar panels.  Even if we assume perfect efficiency and a desert locale, that's 31 panels and $1240...assuming it's possible to find 15 such cragislist deals. Not great, even at minimal power requirements.

### Oil

Finally, how about a classic gas generator? Except that gas gets expensive, fast.  Alternative: diesel engine running veggie oil.  This idea is a _bit_ more fleshed out, because I like it the best: it's reliable, produces a lot of power, cheap to set up,and cheap to run.  A premade all-in-one is going to run $10k or more, so this is DIY all the way!  Which means a building to house the generator installation will probably be a good idea. 

![generator installation](/images/diesel/generator_installation.png)

There's a few different ways this could be set up.  Each of them involve a diesel engine, like this one I found on Craigslist: 

![diesel engine](/images/diesel/engine.jpg)

1. Direct with generator

This is the best version for constant, high load. The engine is connected directly to the generator, and the generator creates AC current at whatever frequency the engine drives it at: which means you have to run the engine at a specific speed in order to make 60Hz household current.  This is an example; in the second image, you can see where you can hook it into your wiring system; it can provide a full 240 Volts at the proper 60Hz, if operated correctly. It's called a "Single-Phase AC Syncronous Generator."

![generator](/images/diesel/generator.jpg) ![generator 2](/images/diesel/generator_2.jpg)

The downside is obvious: if you can't run your generator at a consistent 1800 rpm, then you'll fry the electronics hooked into the electricity it's producing. Not great. Plus, what if you don't need a whole lot of power right now? Tough luck - you can't idle the engine, or the power won't be at the right frequency and you won't be able to use it for anything.

2. Direct with inverter & generator

That's where inverter-generators come in: generate whatever sort of dirty AC weird-frequency power you like (at whatever engine speed is convenient), convert it to clean DC, then convert it _back_ into clean AC. You lose efficiency at each conversion, but you don't have to waste energy (and noise) running the generator at full tilt all the time. This is what most [small portable generators](https://www.harborfreight.com/generators-engines/generators/inverter-generators.html) are - the little things you can take camping. 

Trouble is, I'm not totally sure how to construct one of these from the constituent pieces - the one place I found so far that describes a DIY approach gave opaque instructions that seemed to be asking me to build the AC->DC component from scratch.  I think a car alternator performs that function; but it also sounds like a [truck alternator](http://www.delcoremy.com/alternators/find-by-model-family/36si) would be designed for the higher amperage I'm aiming for. 

    170 Amps x 12 Volts         = 2040 Watts
    2040 Watts x 72% Efficiency = 1468 Watts
    1468 Watts / 120 Volts      = 12.24 Amps

...and that, ladies and gents, is why we don't use vehicle alternators in our DIY inverter-generators.  

3. Indirect with alternator & batteries