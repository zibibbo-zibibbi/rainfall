# Some performance testing

First of all, I wanted to measure the single-core performance of your code on my system, as a reference point (my laptop is slower than yours). Here is C++:

```
    zibibbo@laptop:~/rainfall$ g++ -std=c++11 -O3 rainfall.cpp -o rainfall
    zibibbo@laptop:~/rainfall$ ./rainfall
    995360342 creation: 58 draining: 0 tot: 58
    zibibbo@laptop:~/rainfall$ ./rainfall
    995360342 creation: 59 draining: 0 tot: 59
    zibibbo@laptop:~/rainfall$ ./rainfall
    995360342 creation: 59 draining: 0 tot: 59
    zibibbo@laptop:~/rainfall$ ./rainfall
    995360342 creation: 59 draining: 0 tot: 59
```

So, it's about 58ms. Now C#:

```
    zibibbo@laptop:~/rainfall$ mcs rainfall.cs
    rainfall.cs(89,9): warning CS0219: The variable `w' is assigned but its value is never used
    Compilation succeeded - 1 warning(s)
    zibibbo@laptop:~/rainfall$ ./rainfall.exe
    world creation: 458.5021
    world draining: 0.3795
    total: 458.8816
    zibibbo@laptop:~/rainfall$ ./rainfall.exe
    world creation: 457.7232
    world draining: 0.3732
    total: 458.0964
    zibibbo@laptop:~/rainfall$ ./rainfall.exe
    world creation: 460.8418
    world draining: 0.3745
    total: 461.2163
```

Keep in mind that I'm on Linux, so I had to use the Mono compiler, which is probably slower that Microsoft's, and I also wasn't able to find any optimization options for the compiler, so the numbers above should be taken with a grain of salt, but it's about 458ms.

Moving on to the Haskell code, I first wanted to point out that I think your version of the code (rainfall-A.hs) mismeasures the actual speed of the algorithm in question, as it includes the time needed to generate the random input. I fixed it in rainfall-B.hs. Running the two:

```
    zibibbo@laptop:~/rainfall$ ghc -rtsopts -O2 rainfall-A.hs
    [1 of 1] Compiling Main             ( rainfall-A.hs, rainfall-A.o )
    Linking rainfall-A ...
    zibibbo@laptop:~/rainfall$ ./rainfall-A +RTS -K1000000000
    999735067
    14.776
    zibibbo@laptop:~/rainfall$ ./rainfall-A +RTS -K1000000000
    1000166310
    14.796
    zibibbo@laptop:~/rainfall$ ghc -rtsopts -O2 rainfall-B.hs
    [1 of 1] Compiling Main             ( rainfall-B.hs, rainfall-B.o )
    Linking rainfall-B ...
    zibibbo@laptop:~/rainfall$ ./rainfall-B +RTS -K1000000000
    999549698
    1000448528
    9.156
    zibibbo@laptop:~/rainfall$ ./rainfall-B +RTS -K1000000000
    999595388
    1000402931
    9.2
```

With that fixed, the time I get is 9.2ms, about 160 times slower than C++, and 21 times slower than Mono/C#.

Now, let's try to improve the performance of the Haskell code. The first, obvious change, is to replace the lazy, boxed lists with strict, unboxed arrays, using the Data.Vector.Unboxed package. The changes to the code are minimal. This is the list version:

```haskell
    rainfall :: [Int] -> Int
    rainfall xs = sum (zipWith (-) mins xs) where
      mins = zipWith min maxl maxr
      maxl = scanl1 max xs
      maxr = scanr1 max xs
```

and this is the array version (rainfall-C.hs):

```haskell
    import qualified Data.Vector.Unboxed as V


    rainfall :: V.Vector Int -> Int
    rainfall xs = V.sum (V.zipWith (-) mins xs) where
      mins = V.zipWith min maxl maxr
      maxl = V.scanl1 max xs
      maxr = V.scanr1 max xs
```

Let's run it:

```
    zibibbo@laptop:~/rainfall$ ghc -O2 rainfall-C.hs
    [1 of 1] Compiling Main             ( rainfall-C.hs, rainfall-C.o )
    Linking rainfall-C ...
    zibibbo@laptop:~/rainfall$ ./rainfall-C
    1000176980
    999820324
    0.224
    zibibbo@laptop:~/rainfall$ ./rainfall-C
    999845362
    1000154161
    0.224
    zibibbo@laptop:~/rainfall$ ./rainfall-C
    1000204914
    999794529
    0.228
    zibibbo@laptop:~/rainfall$ ./rainfall-C
    999988927
    1000010063
    0.232
    zibibbo@laptop:~/rainfall$ ./rainfall-C
    999924810
    1000073196
    0.228
    zibibbo@laptop:~/rainfall$ ./rainfall-C
    999762551
    1000234346
    0.228
```

Performance now seems to be reasonable, the median time is 228ms, about 40 times faster that before, twice as fast as the Mono/C# version, but still 4 times slower than C++. And bear in mind that generating the array of input integers (time not shown) is still very slow though. Another simple optimization we can make is to replace scanl1 and scanr1 with their strict cousins, scanl1' and scanr1' (rainfall-D.hs). This is the new code:

```haskell
    rainfall :: V.Vector Int -> Int
    rainfall xs = V.sum (V.zipWith (-) mins xs) where
      mins = V.zipWith min maxl maxr
      maxl = V.scanl1' max xs
      maxr = V.scanr1' max xs
```

and here's the results:

```
    zibibbo@laptop:~/rainfall$ ghc -O2 rainfall-D.hs
    [1 of 1] Compiling Main             ( rainfall-D.hs, rainfall-D.o )
    Linking rainfall-D ...
    zibibbo@laptop:~/rainfall$ ./rainfall-D
    999767910
    1000231087
    0.128
    zibibbo@laptop:~/rainfall$ ./rainfall-D
    1000147637
    999849360
    0.124
    zibibbo@laptop:~/rainfall$ ./rainfall-D
    1000123632
    999874571
    0.124
    zibibbo@laptop:~/rainfall$ ./rainfall-D
    999953402
    1000046018
    0.128
```

Now it's about 128ms, a 45% improvement. 3-4 times faster than Mono/C#, but C++ is still more than twice as fast. The last optimization I was able to think of was merging the two zipWith operation, although in this case the changes to the code are more extensive, and probably come at the expense of clarity:

```haskell
    rainfall :: V.Vector Int -> Int
    rainfall xs = V.sum depths where
      depths = V.zipWith3 (\l r x -> (min l r) - x) maxl maxr xs
      maxl = V.scanl1' max xs
      maxr = V.scanr1' max xs
```

Here's the results:

```
    zibibbo@laptop:~/rainfall$ ghc -O2 rainfall-E.hs
    [1 of 1] Compiling Main             ( rainfall-E.hs, rainfall-E.o )
    Linking rainfall-E ...
    zibibbo@laptop:~/rainfall$ ./rainfall-E
    999767287
    1000231891
    0.112
    zibibbo@laptop:~/rainfall$ ./rainfall-E
    1000055451
    999942293
    0.112
    zibibbo@laptop:~/rainfall$ ./rainfall-E
    999899106
    1000099669
    0.112
```

It's 112ms, a full 4 times faster than Mono/C#, and within a factor of 2 from C++. Still, that was the last optimization I had, and it wasn't enough, C++ is still clearly ahead. But it's interesting to see what happens if we switch from integers to floating point numbers for the heights of the towers. This has the effect of reducing the benefits C++ and Mono/C# get from early loop termination in the Drain() method (a tower that is higher than any other would have the same effect in the integer version). Let's start with C++ (rainfall-fp.cpp):

```
zibibbo@laptop:~/rainfall$ g++ -std=c++11 -O3 rainfall-fp.cpp -o rainfall-fp
zibibbo@laptop:~/rainfall$ ./rainfall-fp
9.99927e+08 creation: 104 draining: 94 tot: 198
zibibbo@laptop:~/rainfall$ ./rainfall-fp
9.99927e+08 creation: 104 draining: 91 tot: 196
zibibbo@laptop:~/rainfall$ ./rainfall-fp
9.99927e+08 creation: 105 draining: 94 tot: 200
zibibbo@laptop:~/rainfall$ ./rainfall-fp
9.99927e+08 creation: 105 draining: 92 tot: 197
```

It's 196ms, about 3.4 times slower than with integer numbers. Let's now try with Mono/C# (rainfall-fp.cs):

```
    zibibbo@laptop:~/rainfall$ mcs rainfall-fp.cs
    rainfall-fp.cs(89,12): warning CS0219: The variable `w' is assigned but its value is never used
    Compilation succeeded - 1 warning(s)
    zibibbo@laptop:~/rainfall$ ./rainfall-fp.exe
    world creation: 465.5362
    world draining: 254.0411
    total: 719.5773
    zibibbo@laptop:~/rainfall$ ./rainfall-fp.exe
    world creation: 464.9108
    world draining: 255.5964
    total: 720.5072
    zibibbo@laptop:~/rainfall$ ./rainfall-fp.exe
    world creation: 467.5509
    world draining: 252.8726
    total: 720.4235
```

About 720ms, 57% slower than before, and nearly 4 times slower than C++. Finally, let's run the Haskell version (rainfall-F.hs):

```
    zibibbo@laptop:~/rainfall$ ghc -O2 rainfall-F.hs
    [1 of 1] Compiling Main             ( rainfall-F.hs, rainfall-F.o )
    Linking rainfall-F ...
    zibibbo@laptop:~/rainfall$ ./rainfall-F
    9.997301194600787e8
    1.0002626918880427e9
    0.124
    zibibbo@laptop:~/rainfall$ ./rainfall-F
    9.999921063011181e8
    1.0000021759068646e9
    0.128
    zibibbo@laptop:~/rainfall$ ./rainfall-F
    9.997913379553406e8
    1.0002030990805962e9
    0.128
```

Here Haskell seems to be the clear winnner. It finishes in 128ms, a 15% slowdown compared to the integer version, but still faster that C++ by about a third, and 5-6 times faster than Mono/C#.
