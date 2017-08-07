### Hollow blocks

**Update 1**: Fixed a compile error caused by a last-minute untested change

I've written a first draft of a tentative solution for the rainfall problem with hollow blocks. It's a work in progress, and it's not even really complete, but it already works with very small inputs. The code is in [hollow-blocks-A.hs](./hollow-blocks-A.hs). I'll keep updating both the code and this document, but the old versions will be always available through the commit history. Performance is terrible, among other things I'm still using lists everywhere, even when random access is required, but I think that can be fixed. I've done a bit of testing, but don't be surprised if you find a bug. Just let me know, and I'll fix it, if I can. Also note that I've only a basic knowledge of Haskell, this may well be the most complex Haskell program I've ever written, so please don't blame the language, or the paradigm, or anything else, for what is just incompetence on the developer's part.

With all that in mind, here's how it works: we first divide the world in a set of interconnected "cells", that is, rectangular regions of space that that can contain water. Whether that region is a piece of sky, or a hollow section of a tower, is irrelevant. Cells can only touch one another by the sides, not by the floor or ceiling. Then for each cell *c* we define a quantity, let's call it *L(c)*, as follow: suppose it rains for a sufficiently long time, until the entire system reaches a stationary/equilibrium state. At that point, a number of things may happen:

  * The cell ends up contains some water. In that case, *L(c)* is the maximum level the water reaches in that particular cell and in all the cells that are connected to it through water. That is, suppose you release a little fish inside that particular cell, and leave it free to move from cell to cell as long as it never jumps out of the water. The maximum altitude that fish can reach is *L(c)*
  * The cell is "leaky", that is, water never accumulates. In that case, *L(c)* is equal to the altitude of the floor of that particell cell
  * If a cell is never reached by the rain, then *L(c)* is equal to the altitude of the floor of the cell, just like with leaky cells.

Once we know *L(c)* for all the cells in the system, it's straightforward to calculate the total amount of water that is retained after a sufficiently long rainfall. To calculate *L(c)* we'll use an iterative process: we'll start by assigning each cell an upper bound for *L(c)*, which will be the altitude of the floor for cells that the rain cannot reach or that can leak directly off the side (that is, those on the first or last tower), and infinite for all the others. After that, we'll start applying a simple constraint: the value of the upper bound of *L* for any particular cell cannot be higher that the value of the same quantity for any of the cells it is connected to, unless that value happens to be lower than the altitude of the cell's own floor. We keep propagating this constraint until there's nothing left to propagate, at which point those upper bounds will have collapsed into the actual values of *L(c)* (this should be proved, of course, and I haven't done it, but it seems to me intuitively right...).

Note that at this point, we have mapped our original problem into a totally abstract graph problem: we have a set of nodes (the cells), a set of edges (there's an edge between two nodes when the corresponding cells are connected), an initial value for the state associated with each node and an update function that given the current state of a particular cell and all its neighbours returns a new value for the cell's state. We keep applying the update function until we reach a fixpoint.
The very same graph propagation algorithm is also used, with a different state and update function, to figure out which cells can be reached by the rain.

The code is divided into three parts, the main function (rainfall), the part that calculates all geometric information (geometry) and the graph fixpoint function.

The input is provided in a format that is meant to be easy for a human to write: each tower is represented by a list of numbers, the height of alternating sections of solid and hollow concrete, starting with a solid one: the first value can be zero if the tower starts with a hollow section. Right now I'm using integers, but everything would work just as well with floating point numbers.

The first step is to produce a list of all "cells" in the system, along with the all the connections between them, represented as an adjacency list. That's what the *geometry* function does. Every cell is represented as a 3-tuple, (X, floorY, height), where height is set to 0 for cells at the top that don't have a ceiling. Nothing would prevent anyone, of course, from using records (or even union types) instead, it's just easier when using a repl to deal with tuples. After that we compute which cells are reachable by the rain, then *L(c)* and finally the amount of water left in the system.

The one thing that I haven't really implemented is the fixpointV function, I've just provided a sort of "operational/constructive specification" for it, which is enough to do some testing and deal with very small inputs, but not much more:

```haskell
    fixpointV :: Eq a => ([a] -> Int -> a) -> [[Int]] -> [a] -> [a]
    fixpointV f _ v = if v == v' then v else fixpointV f v'
      where v' = [f v i | i <- [0 .. length v - 1]]
```

It takes three arguments: the last one is the initial state of all nodes in the graph, the second one is the set of edges of the graph, represented as an adjacency list; and the first one is the update function which takes the current state of the entire graph, and the index of a node, and returns a new value for the state of that node.

Such a fixpoint function is of course reasonably easy to implement in a language that provides mutable array, but becomes (as far as I can tell) a lot more complicated without them. I guess in Haskell that would have to be done using the ST monad, but doing that is sort of above my pay grade. I'll try to do it (maybe I'll even start to get the hang of monadic programming in the process), but any sort of help from experienced Haskell programmers would be appreciated, if any of them were to read this (in particular I'd like to know if there's a way to implement it that preserves the parallelism that is intrinsic to the problem).

The whole algorithm that I'm using is based on stationary-state/equilibrium analisys, and I make no claim whatsoever about it being able to simulate the dynamics of the systems. It's actually even worse than that, in the sense that I haven't figured out yet an algorithm to do that, at least not in the presence of hollow blocks. But note that the bulk of the work went into implementing *geometry* and *fixpointV* (at least if I had actually implemented the latter). The *fixpointV* may or may not be useful to implement the dynamic simulation, I don't know, but no matter what algorithm is used, I would be very, very surprised if it didn't make use of the information computed by *geometry*. So in all likehood an implementation of the dynamic simulation wouldn't start from scratch, but would build on what's already there.

I look forward to seeing your own code, but in the meantime I've a question. You solved the problem using a more capable (and more complex) problem-solving strategy/algorithm (is there any difference between the two?), and it seems to me that the extra flexibility you get comes from that. Now, a strategy/algorithm can be implemented in different ways: I haven't actually tried, but it seems to me that your own strategy/algorithm could have been implemented just as well in perfect hipster-Haskell style (and conversely, maybe the "height of shortest tower" algorithm could have been implemented using a domain-oriented style?). Now, is the point you are making about strategies/algorithms, (that is, are you saying that we should not aim for the simplest algorithm that can solve the problem, but we should aim for something more general, and more complex, just in case), or is it about the actual implementation of those strategies/algorithms (that is, are you saying that implementing your own strategy/algorithm in a hipster-Haskell style would have resulted in less flexible code?). If it's the latter, you should be comparing different implementations of the same strategy/algorithm, not different implementations of different algorithms. Or are you saying that the two are inextricably linked? Or that some algorithms are more difficult to implement (efficiently) in a functional language with no mutability (I totally agree on this one, by the way)? Or something else again? I don't understand. Can you clarify?
