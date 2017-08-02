I wanted to ask a couple questions about the changes you proposed in your paper, I'm not clear how that would work in your code (and/or with your solving strategies). Let's start with **Change 2 – harder than it should**, the problem of determining the skyline once a given amount of rain has fallen. Consider the following skyline (each *#* symbol represents a block, of course, and let's make it easy and say that each block is a square whose side is 1 meter):

```
    #   ##
    #   ##
    # # ##
    # # ##
    # # ##
    ######
    ABCDEF
```

How would your code/strategy figure out how much water would be left on top of towers B and D after 1 meter of rain has fallen? The problem is that half of the water that falls on A will fall off the left end, and half of it will follow on B and stay there. Similarly with C, E and F, with the added problem that E and F will leak into each other.
And once you start to account for the fact that any given "block" of water can leak in either direction, how would you exactly determine how the leak is split? That's because the geometries of the skyline vary over time, and with them the flows of water. Consider the following skyline:

```
    #
    #      ##
    # #  ####
    # #######
    # #######
    #########
    ABCDEFGHI
```

Initially, the fate of every drop of water the falls on one of the towers will be the following:

```
  A         -> 1/2 off the left, 1/2 on B
  B         -> stays on B
  C         -> 1/2 on B, 1/4 on D and 1/4 on E
  D/E/F/G   -> 1/2 on D, 1/2 on E
  H/I       -> 1/2 off the right, 1/4 on D, 1/4 on E
```

So both D and E will be receiving 2.75mms of water for each millimeter of rain that falls from the sky. So the D/E trough will fill after 4/11 (= 0.363636...) meters of rain have fallen, and at that point all the flows will change as follow:

```
  A         -> 1/2 off the left, 1/2 on B
  B         -> stays on B
  C/D/E/F/G -> all on B
  H/I       -> 1/2 off the right, 1/2 on B
```

The simplest algorith I can think of would have to do the following:

  1) Merge all adjacent tower with the same height, as the notion of towers that leak into each other is problematic. It can be done in one loop/scan
  2) Determine final destination of a drop of water that falls on each of the towers. Can be done with two loops/scans, one from the left and one from the right
  3) Calculate how long it will take to fill the first trough. Calculate the new skyline at the time that happens
  4) Using that new skyline as the next starting point, go back to step one

Everything else would just be optimization, which is of course the hard part. Incidentally, you would also have to use floating point (or rational) arithmetics even if the initial problem was formulated in terms of integers. And even the simpler problem of determining how much water would be left after a given time, without explicitly determining the final skyline seems pretty hard to me.
Yet you claim that both your problem solving strategy and your code structure would stand up, and would accept that change gracefully? How so? I have difficulty even understanding how the initial, conceptual strategy (the N*M cells) can tackle this. What am I missing? Can you explain or, even better, actually write the code, if it's not too much effort?

I also don't understand how you would adapt you strategy and code to the addition of hollow blocks. Consider the following skyline, where 'X' denotes a hollow block:

```
    5 ######X##
    4 XXX#XXX##
    3 ##X#X####
    2 ##XXX####
    1 #########
      ABCDEFGHI
```

Hollow blocks E4/F4/G4/G5 would not retain any water of course, but how would you figure that out with your current approach, or even with your initial conceptual strategy? Can you explain?
