---
layout: post
title: Cheap Electricity through Alternative Means
author: umhau
description: "Cliche Survivalism"
tags: 
- diesel
- electricity
- vegetables
- AC/DC
- engines
- power
- solar
- thermal
- generation
categories: other
---

Crypto mining is apparently getting pretty big, and apparently GPU crypto mining is still a thing these days. The cool part is how it's become an arbitrage (big word...am I using it right?) to convert electricity into dollarinos.  Since I have some space, and my neighbors aren't likely to be bothered by noise pollution, I think it could be valuable to find the cheapest (legal) source of electricity I can and convert it into crypto.

Considered options:

## Thermal power

Based on the difference between static ground temp and the outside temp, doesn't seem super practical: dig a horizontal hole, feel the gentle breeze as the air temperature evens out, and then rig a fan to spin with that breeze. Hey - give it a week, you might charge your phone!

## Gravity

(Gravity mechanism: manually hang a weight in the air, attach a generator to the other end; weight slowly falls, generator spins, electricity comes out.) Gravity-based mechanisms are apparently very inefficient. 

    100 kg x 9.8 m/s^2 gravity force x 10 meters = 9.8kJ = 2.72 Watt-hours
    1 AA Battery = 3 Watt-hours

A 100kg weight falling 10 meters generates about the energy equivalent of a AA battery -- so not super great. I don't feel like hoisting a couple of tons of rock into the air just to charge my laptop.

## Wind

This gets into tricky regulations, and even more feasibility constraints. There might be limits on whether I can legally put up a tower, and I'm not sure there's a lot of wind where I am.  Plus, those towers are expensive.

## Solar

These are better than I guessed at first. That being said, I don't have access to a lot of sunlit square footage. Secondly, new solar panels are also _expensive_.  Third, you have to set up not just the solar panels, but enough batteries to [survive the darkness](https://www.imdb.com/title/tt0134847/).  

Craigslist is a great source of panels, however. I found these for an ask of $80:

![](/images/diesel/solar_panels.jpg)

They produce 100 Watts each. If you recall your electrical engineering, that means at perfect efficiency:

    (100 Watts x 2 panels) / 120 Volts = 1.66 Amps

And, of course, that's on a devestatingly sunny day with a physics-defying DC->AC inverter.  Expect much less than that; possibly, those two panels would get you a reliable 1 Amp on a sunny day.  Now consider that a standard household circuit has a fuse limit of (probably) 20 Amps, and a microwave draws 9-15 Amps.  A refrigerator uses another 7 Amps. Your laptop probably uses another 5 Amps (...ish). A portable AC unit takes another 5 Amps, and a Central AC unit might take a whole 15-20 Amps.   

So far, we're up to `9 + 7 + 5 + 5`, conservatively.  That's 26 Amps total, and 52 (fifty-two!) of those solar panels.  Even if we assume perfect efficiency and a desert locale, that's 31 panels and $1240...assuming it's possible to find 15 such cragislist deals. Not great, even at minimal power requirements.

## Diesel engine + Veggie Oil

I like this the best: it's reliable, produces a lot of power, cheap to set up,and cheap to run.  A premade all-in-one is going to run $10k or more, so this is DIY all the way!  Ouch. 

However, used vegetable oil can be found for free, and with the right mechanical arrangement this can be a dirt-cheap energy supply. Looks like a [4-cylinder motor](http://www.centralmainediesel.com/order/Kohler-Diesel-DC-Generator.asp?page=Kohler_Diesel_DC) can use something like a third of a gallon of diesel an hour; I assume veggie oil is less efficient.  If biofuel consumption is closer to 0.5 gallons per hour, then if I run the generator on idle constantly, a week's fuel requirement would be:

    0.5 gallons per hour * 24 hours * 7 days = 84 Gallons per week
    84 gallons per week * 4 = 336 gallons per month
    1 gallon = 8 lbs
    84 gallons per week * 8 lbs = 672 lbs per week
    336 gallons per month * 8 lbs = 2688 lbs per month

Looks like, if the suppliers (local restaurants) are willing, I could do bi-monthly trips to pick up oil, and that would be within the weight limits of my vehicle and (barely over) the volume limits of one of those giant 325 gallon plastic containers. Note this is a conservative estimate, since I'm not likely to use a 4-cylinder engine, and the diesel consumption is less than what I'm guessing here for biofuel.

![](/images/diesel/325gal_container.jpg)

The problem becomes sourcing the veggie oil.  There's a decent population center nearby, but given the popularity of the idea of burning veggie oil, it's possible there's no available sources left. 
