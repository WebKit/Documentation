# Offscreen Canvas 2021 Update

## Overview

Speaker : Chris Lord

Slides available [here](https://cloud.igalia.com/s/GLHpqd5Y87tB4QY).

## Q&A

heycam: great work, I like it. I was curious what work needs to be done to bring this to apple ports, I am curious about (...gpu?)

chris: Currently the GTK and WPE ports cannot use the GPU process... to do that would probably involve some pretty novel work, I don't know just off the top of my head

myles: Such novel work probably wouldn't be port specific tho?

chris: Yeah... I hope the way it is architected also means that i hope it wouldn't be impossibly hard.

heycam: I guess in the GPU process we'd want to have parallel threads for the canvases doing work

myles: this is really exciting, thumbsup

chris: I'm really excited to see it land - at least the linux ports are more than a proof of concept at this point, there's certainly still work to do on the apple ports, but it's doable and we can help where we can

cameron: Are there any parts that aren't done in the linux

chris lord: I think that there is something like bitmap context - the feature that lets you get a canvas context for drawing to an image element? I think that is right? But as far as I know that doesn't work right now... For no particular reason, we just havent' worked on it

imagebitmap basically works, there might be edges, we just haven't spent the time

some things i'm not sure really - they are missing in the canvas implementation, we'll get it for free

smfr: what about webgl context?

chris l: yes, techically, but in linux we don't have the GPU process, and I think getting that to work wouldn't be entirely trivial

myles: can I ask, what prompted you to work with?

chris: really, it is just the thing I was tasked with when I came here... I have done things with async rendering and compositor in firefox in the past, so I have been working on graphics stuff for browsers for some time - and I dont' like to leave things half finished, so it got done
