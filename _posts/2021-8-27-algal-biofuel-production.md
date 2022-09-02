---
layout: post
title: biofuel research, session 1
author: umhau
description: "general questions"
tags: 
- biofuel
- algae
- biology
categories: other
---



Trying to understand the use and production of biofuels; this session is dedicated to discovering the 'lie of the land'. It occurs to me that I could produce my own biofuel from algae. I'd like to see how, and if, that's possible and feasible. 

One of the big questions in my mind is how much algae I need to be growing in order to produce a certain quantity of biofuel per hour. This is supposed to power a diesel motor that's running constantly and using about half a gallon of fuel per hour.

The other big question I have is, what the energy input to the algae is. Is it sunlight? Can this stuff only be grown in daylight, outdoors? Or does it feed on chemicals like carbon dioxide, the way a tree does? Maybe, all it really needs are flourescent lights, carbon dioxide, and lots of water. 

That would give it the hydrogen and the carbon needed for the hydrocarbon output, but I wonder how I can obtain that much carbon dioxide. There's not a lot in air -- apparently only 0.039% by volume -- so pumping atmosphere through the system would likely be to inefficient to work.

# fundamental limitations

## photosynthesis

Algae will not grow when it has no light. It may be possible to use artificial light, but that means far less energy input to the system, thermodynamically speaking. 

![](/images/diesel/algae_pipes.jpg)

Ponds, raceways, pipes, and thin flat boxes: the current best-practices for exposing algae to light. There's significant tradeoffs to each. In general, only the algae exposed to light will be growing, and therefore we want all the algae to be exposed all the time. 

- Unless, there's a known upper limit to the amount of light algae needs per unit of time - or there's a plataeu, after which additional light has only limited improvement. This does seem to be the case: [in this site](http://www.algaeproductionsystems.com/equipment.html), it appears that the feeding system is separate from the photosynthesis system. The question then becomes, what's the ratio?

Turns out, there is such an upper limit. Algae needs both light and dark, in order to perform different chemical reactions. There's research that's been done into the proper ratio, but it seems that that ratio is close to a 16 hour daylight cycle. 

> The suggested way to increase light rather than increasing the transparent surface and bringing the algal growth to the light is to use alternative ways to bring light to the biomass layers by using milli and micro scaled multi structures – fleece of glass fibers can be used – **or a build in light conductive structure can be used to guide light into a compact closed reactor**. Another way is to use lenses effect or LEDs light to distribute the light uniformly inside the reactor. _[emphasis mine]_

I like that idea. Sure seems like that could make things a lot easier -- I'm now imagining digging a giant hole, and putting a bunch of arylic tubes into it at regular intervals, with the other ends of the tubes attached to some kind of giant solar collector. Or do the same thing at a smaller scale in vats with artificial light.

> Rochet M., et. al., 1986, studied certain conditions in southern Hudson Bay (Canadian Arctic) from March to May 1983 to observe the response of sea-ice microalgae to different changes in light intensity and quality. **When algal growth was incubated under blue light it doubled as compared to the growth under white light.** According to the availability of blue green light environment ice algae had adaptive response to it and showed high concentration of chlorophyll. On the other hand the same algae responded to light spectrum when in incubated under white illumination by increasing their chlorophyll. "The ability to chromatically adapt may become a critical factor in species competition". 

> Kitaya Y., et. al., 2005, investigated the effects of temperature; CO2/O2 concentrations and light intensity were examined on cellular multiplication of microalgae. Microalgae were cultured under five levels of temperatures from 25 ̊C to 33 ̊C, three levels of CO2 concentrations from 10% to 30 %, and six levels of photosynthetic photon flux from 20 to 200 μ mol m^-2 s^-1.The results demonstrated that **the highest multiplication rate of the microalgae cells was at temperature of 27-31 ̊C, CO2 concentration of 4%, O2 concentration of 20% and light flux of about 100 μ mol m^-2 s^-1**. 

> Mata T., et. al., 2012, analyzed the factors that may affect the production of biomass and the treatment of brewery waste water. Many parameters were studied to reach the highest biomass production and the most suitable conditions for cultivating algae. Those conditions were in an aerated culture and exposing the growth to a 12 h period of day light at 12000 lux intensity. The maximum biomass obtained was **0.9 g of dry biomass per liter** of growth on the 9th day.

> Jacob-lopes E., et. al., 2009, evaluated growing algae under different light cycles, and **24:0 (night: day)** respectively. A reduction in biomass production was observed in parallel with the reduction in light period duration. 

> Janssen M., 2002, studied light/dark cycles to examine the efficiency of light utilization in (PBRs). **A medium frequency light/dark cycles –from few seconds to 1000s- lauded to higher photosynthetic efficiency** in the PBRs in comparison to constant light levels.

> Cheirsilp B., et. al., 2012, **investigated chlorella sp.and Nannochloropsis sp. to be the best algae species for production of biodiesel.** For the production of higher biomass amount with high lipid content the growth was **cultivated under stepwise increasing intensity as a fed-batch. This procedure insured approximately twice lipid production than conventional batch cultivation.** The composition of the main fatty acid was appropriate for biodiesel production. 

> The **productivity of microalgae can be enhanced by cultivating the culture under light emitting diodes (LEDs) with peak emittance of 680 nm, this will result in doubling the number of cells produced without changing the cell volume** then the culture is exposed to white light in order to enlarge the cells size so the overall biomass will increase. 

## carbon dioxide

Namely, how do you get enough of the stuff to the algae? Apparently, it's a known problem. One solution is to bubble the stuff through your enclosed system, but then you have to be able to source enough of the gas to provide the carbon for your metric tons of hydrocarbon fuel - good luck. 

Another solution is the big open-air vats of algae, where it just grabs carbon dioxide out of the abmbient air. Not super efficient, but it solves the supply chain issue. 

I'm trying to think of a way to use ambient air, without the inefficiency. Possibly some way to force-pump the air through the bioreactor broth to maximize the amount of CO2 that the algae is exposed to. 

- There's a maximum amount of air that can be dissolved in water; it follows [Henry's Law](https://www.engineeringtoolbox.com/air-solubility-water-d_639.html) which means that "the amount of air that can be dissolved in water increases with pressure and decreases with temperature."

![](/images/diesel/air_water_solubility.jpg)

However, dissolved air may be useful, but it also isn't able to be swapped out with fresh air as rapidly. 

- It may be worth using bubbles, like a giant fish tank. That way the air passes through quickly, and as an added plus, agitates the water. 
- Alternately, it may be possible to induce a temperature gradient such that air is dissolved at the bottom of the tank, but the warmer liquid at the top causes the air to be released. (Also, the physics works: warmer water stays at the top, and less-dense, water-with-air rises to the top as well.) Downside: probably very hard to do the dissolving.

Limitation: light required at all times. No thick pools, unless very temporary.

# algae types

## botryococcus braunii

A green colonial microalgae, which is an unusually rich source of hydrocarbons and other chemicals. This is an example of the sort of algae I'd be trying to cultivate.

The per unit area yield of oil from algae is estimated to be from 58,700 to 136,900 L/ha/year, depending on lipid content, which is 10 to 23 times as high as the next highest yielding crop, oil palm, at 5 950 L/ha/year.

https://en.wikipedia.org/wiki/Algae_fuel#Biodiesel

Biodiesel has 12% lower energy content than diesel, this leads to an increase in fuel consumption
of about 2–10%

https://sci-hub.st/https://doi.org/10.1016/j.rser.2012.01.003

# advantages and disadvantages of algae and biofuel

![](/images/diesel/biodiesel_disadvantages.jpg)

![](/images/diesel/biodiesel_advantages.jpg)

