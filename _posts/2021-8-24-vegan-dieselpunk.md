---
layout: post
title: vegan dieselpunk
author: umhau
description: "Converting Peanut Oil into Money & Resiliency"
tags: 
- diesel
- electricity
- vegetables
- AC/DC
- engines
- power
categories: other
---

Excellent resource: [Build a High Power Homemade AC/DC Generator System](https://theepicenter.com/blog/ac-dc-generator/)

The previous post described various alternatives to generate cheap power. I like the diesel motor running vegetable oil, so this is an exploration of the details of making that work.  There's a few different ways this could be set up.  Each of them involve a diesel engine, like this one I found on Craigslist: 

![](/images/diesel/engine.jpg)

In general, the question is what kind of electricity the rotational energy of the motor is converted into, and how the potential for aberrations in the RPMs is handled. 

Some definitions before we get started: 

- **motor** This is the thing that converts liquid fuel into rotation. In this case, it's a diesel engine modded to drink vegetable oil of some kind. 
- **alternator** Takes rotation and converts it into alternating current. Is a rotating magnetic core, with a stationary wire around it, in which a current is induced.
- **generator head** a domain-specific term for an alternator designed for attachment to a motor for the purpose of electricity generation. You can get these in single-phase, two-phase, or even three-phase variations. Dunno what the functional difference is, besides the easy access to 240 volts in the two-phase system.
- **transformer** Used with alternating current, not DC; transforms high voltage into low voltage, and _vice versa_. 
- **generator** a device that converts mechanical power into electrical power.
- **inverter** changes direct current (DC) into alternating current (AC)
- **rectifier** changes alternating current (AC) into direct current (DC). This isn't strictly necessary, since a diode and a capacitor will cut half the cycle off and flatten the remaining curve. You need the rectifier to keep the lower half of the AC sine wave (the other half of the electricity output). 

## Motor -> AC Generator

This is the best version for constant, high load. The engine is connected directly to the generator, and the generator creates AC current at whatever frequency the engine drives it at: which means you have to run the engine at a specific speed in order to make 60Hz household current.  This is an example; in the second image, you can see where you can hook it into your wiring system; it can provide a full 240 Volts at the proper 60Hz, if operated correctly. It's called a "Single-Phase AC Synchronous Generator."

![](/images/diesel/generator.jpg) 

![](/images/diesel/generator_2.jpg)

The downside is obvious: if you can't run your generator at a consistent 1800 rpm, then you'll fry the electronics hooked into the electricity it's producing. Not great. Plus, what if you don't need a whole lot of power right now? Tough luck - you can't idle the engine, or the power won't be at the right frequency and you won't be able to use it for anything.

However, you can always use a pulley system to alter the ratios between the generator head and the motor - that way, if you just want to run the motor at a minimim fuel consumption, you can still get the generator head at the correct RPM. 

The AC Generator is called a '[generator head](https://www.alibaba.com/products/generator_head/CID410402.html)' in this context. Find one and hook it onto the motor. It's pretty much that simple, I think. In fact, the image below is what the result looks like: on the left is the generator head, on the right is the generator, they're connected with a belt in a specific ratio, and there's a tensioner in the middle to keep them connected. As the description says, _"built on a brand new Hatz 1B30 engine and brand new Mecc Alte generator head. Vibration isolating base with carry handles."_  It really is that simple.

![](/images/diesel/generator_and_head.jpg)

## Motor -> AC Generator -> DC Rectifier -> AC Inverter

That's where inverter-generators come in: generate whatever sort of dirty AC weird-frequency power you like (at whatever engine speed is convenient), convert it to clean DC, then convert it _back_ into clean AC. You lose efficiency at each conversion, but you don't have to waste fuel (and noise) running the generator at full tilt all the time. This is what most [small portable generators](https://www.harborfreight.com/generators-engines/generators/inverter-generators.html) are - the little things you can take camping. 

To build one, do what you would have done in the previous section - get a motor, attach a generator head. Then, attach a rectifier - this converts the AC power into DC, and it doesn't care too much what that AC looks like. You might need to adjust the voltage first; not sure about that. Then use an inverter (this is expensive!) to convert the DC back into AC. 

### Car/Truck Alternators

An alternator from a car or truck combines the functions of the AC Generator and the DC Rectifier; however, it does not operate at a particularly high efficiency. If I were to use one, however, it seems like a [truck alternator](http://www.delcoremy.com/alternators/find-by-model-family/36si) provides a higher amperage than one pulled from a consumer car.  Some quick numebers: 

    170 Amps x 12 Volts         = 2040 Watts
    2040 Watts x 72% Efficiency = 1468 Watts
    1468 Watts / 120 Volts      = 12.24 Amps

...and that, ladies and gents, is why we don't use vehicle alternators in our DIY inverter-generators.  12 Amps is not even close to enough - we should be getting closer to 9500 Watts output, which would give us (if that's a post-efficiency-loss number):

    9500 Watts / 120 Volts = 79.16 Amps

## Motor -> AC Generator -> DC Rectifier -> Battery Pack -> AC Inverter

I don't know if this is a good idea, but it might be that I can use that DC to directly charge my lead-acid battery collection. If so, I think I can attach the remnants of several of my uninterruptible power supplies (UPS) directly to the batteries, and bypass the need for an expensive high-amp inverter. 

# next steps

Looks like what I need is:

- generator head
- diesel motor

These two need to at least kinda match - don't get a generator head that expects 40 HP, and then get a 10 HP motor. 

Then I have a choice: run the motor at a consistent RPM, and use pulley ratios to run the generator head at its preferred RPM, or run the motor at any RPM it likes attach the generator head to that, attach a rectifier and then an inverter. Or some combination of the two. Inverters are expensive.

Also, a building to house the generator installation will probably be a good idea. 

![](/images/diesel/generator_installation.png)

