import qualified Data.Vector as V
-- import qualified Data.Vector.Unboxed as U


infinite = 1000

floorY  (_, f, _) = f
height  (_, _, h) = if h == 0 then infinite else h

--------------------------------------------------------------------------------

adjacencies :: Int -> [(Int, Int)] -> Int -> [(Int, Int)] -> [(Int, Int)]
adjacencies id1 l1 id2 l2 = if null l1 || null l2 then [] else result where
  (f1, h1)      = head l1
  (f2, h2)      = head l2
  ceiling1      = if h1 == 0 then infinite else f1 + h1
  ceiling2      = if h2 == 0 then infinite else f2 + h2
  overlap       = ((f1 >= f2) && (f1 < ceiling2)) || ((f2 >= f1) && (f2 < ceiling1))
  (id1', left1) = if ceiling1 > ceiling2 then (id1, l1) else (id1+1, tail l1)
  (id2', left2) = if ceiling2 > ceiling1 then (id2, l2) else (id2+1, tail l2)
  rest          = adjacencies id1' left1 id2' left2
  result        = if overlap then (id1, id2) : rest else rest


slice :: Int -> [Int] -> [(Int, Int)]
slice l []          = [(l, 0)]
slice l [s]         = [(l+s, 0)]
slice l (s:(h:[]))  = [(l+s, 0)]
slice l (s:(h:r))   = (l+s, h) : slice (l+s+h) r


toAdjList :: Int -> [(Int, Int)] -> [[Int]]
toAdjList n es = V.toList $ V.accum (\t h -> h:t) empty edges where
  edges = es ++ [(n2, n1) | (n1, n2) <- es]
  empty = V.replicate n []


geometry :: [[Int]] -> ([(Int, Int, Int)], [[Int]])
geometry ss = (cells, adjList) where
  slices'   = map (slice 0) ss
  slices    = zipWith (\i s -> [(i, a, b) | (a, b) <- s]) [0..] slices'
  offsets   = scanl (+) 0 $ map length slices
  cells     = concat slices
  adjs' i   = adjacencies (offsets !! i) (slices' !! i) (offsets !! (i+1)) (slices' !! (i+1))
  adjs      = concat [adjs' i | i <- [0..length slices - 2]]
  adjList   = toAdjList (length cells) adjs

--------------------------------------------------------------------------------

fixpointV :: Eq a => (Int -> a -> [a] -> a) -> [[Int]] -> [a] -> [a]
fixpointV u es ss = if ss == ss' then ss else fixpointV u es ss' where
  ss' = [u i (ss !! i) [ss !! j | j <- es !! i] | i <- [0 .. length ss - 1]]

stepsV :: (Int -> a -> [a] -> a) -> [[Int]] -> [a] -> Int -> [a]
stepsV u es ss n = if n == 0 then ss else stepsV u es ss' (n-1) where
  ss' = [u i (ss !! i) [ss !! j | j <- es !! i] | i <- [0 .. length ss - 1]]

--------------------------------------------------------------------------------

-- rainfall slices n = stepsV update adjList levels' n where

rainfall :: [[Int]] -> Int
rainfall slices = sum water where
  (cells, adjList)  = geometry slices
  reached i r rs    = foldl (||) r rs
  reachable         = fixpointV reached adjList [h == 0 | (_, _, h) <- cells]
  lastSlice         = length slices - 1
  noWater i x       = x == 0 || x == lastSlice || not (reachable !! i)
  levels'           = [if noWater i x then f else infinite | ((x, f, _), i) <- zip cells [0..]]
  update i l ls     = max (floorY $ cells !! i) $ foldl min l ls
  levels            = fixpointV update adjList levels'
  water             = zipWith (\c l -> min (height c) (l - floorY c)) cells levels

--------------------------------------------------------------------------------
---------------------- TEST DATA -- TEST DATA -- TEST DATA ---------------------
--------------------------------------------------------------------------------

testSkylineA :: [[Int]]
testSkylineA = [
    [3, 1, 2],
    [3, 1, 2],
    [1, 3, 2],
    [1, 1, 4],
    [1, 3, 2],
    [3, 1, 2],
    [3, 3],
    [6],
    [6]
  ]

-- 5 ######X##
-- 4 ######X##
-- 3 XXX#XXX##
-- 2 ##X#X####
-- 1 ##XXX####
-- 0 #########
--   ABCDEFGHI

-- 3,6  I,I  I,I  I,I  I,I  I,I  I  I  6
-- 3,6  3,6  I,I  I,I  I,I  I,I  I  6  6
-- 3,6  3,6  3,6  I,I  I,I  I,I  6  6  6
-- 3,6  3,6  3,6  3,6  I,I  6,6  6  6  6
-- 3,6  3,6  3,6  3,6  3,6  6,6  6  6  6
-- 3,6  3,6  3,6  3,6  3,6  3,6  6  6  6
-- 3,6  3,6  3,6  3,6  3,6  3,6  3  6  6
-- 3,6  3,6  3,6  3,6  3,6  3,6  3  6  6

-- [ (0,3,1), (0,6,0),
--   (1,3,1), (1,6,0),
--   (2,1,3), (2,6,0),
--   (3,1,1), (3,6,0),
--   (4,1,3), (4,6,0),
--   (5,3,1), (5,6,0),
--   (6,3,0),
--   (7,6,0),
--   (8,6,0)
-- ]

-- [ [2],        [3],
--   [0,4],      [1,5],
--   [2,6],      [3,7],
--   [4,8],      [5,9],
--   [6,10],     [7,11],
--   [8,12],     [9,12],
--   [11,10,13],
--   [12,14],
--   [13]
-- ]

--------------------------------------------------------------------------------

testSkylineB :: [[Int]]
testSkylineB = [
    [4, 1, 1],
    [4, 1, 1],
    [1, 4, 1],
    [1, 1, 4],
    [1, 3, 2],
    [3, 1, 2],
    [3, 3],
    [6],
    [6]
  ]

-- 5 ######X##
-- 4 XXX###X##
-- 3 ##X#XXX##
-- 2 ##X#X####
-- 1 ##XXX####
-- 0 #########
--   ABCDEFGHI

-- [ (0,4,1), (0,6,0),
--   (1,4,1), (1,6,0),
--   (2,1,4), (2,6,0),
--   (3,1,1), (3,6,0),
--   (4,1,3), (4,6,0),
--   (5,3,1), (5,6,0),
--   (6,3,0),
--   (7,6,0),
--   (8,6,0)
-- ]

-- [ [2],        [3],
--   [0,4],      [1,5],
--   [2,6],      [3,7],
--   [4,8],      [5,9],
--   [6,10],     [7,11],
--   [8,12],     [9,12],
--   [11,10,13],
--   [12,14],
--   [13]
-- ]

--------------------------------------------------------------------------------

testSkylineC :: [[Int]]
testSkylineC = [
    [2, 1, 5],
    [1, 2, 3],
    [2],
    [7],
    [4],
    [1, 1, 2, 1, 3],
    [6]
  ]

-- 7 #    #
-- 6 #  # #
-- 5 ## # ##
-- 4 ## # X#
-- 3 ## ####
-- 2 XX ####
-- 1 #X###X#
-- 0 #######
--   ABCDEFG

-- 2,8  I,I  I  I  I  1,I,I  6
-- 2,8  2,8  I  I  I  1,I,8  6
-- 2,8  2,8  2  I  8  1,I,8  6
-- 2,8  2,6  2  7  8  1,8,8  6
-- 2,8  2,6  2  7  7  1,8,8  6
-- 2,8  2,6  2  7  7  1,7,8  6
-- 2,8  2,6  2  7  7  1,7,8  6
-- 2,8  2,6  2  7  7  1,7,8  6

-- [ (0,2,1), (0,8,0),
--   (1,1,2), (1,6,0),
--   (2,2,0),
--   (3,7,0),
--   (4,4,0),
--   (5,1,1), (5,4,1), (5,8,0),
--   (6,6,0)
-- ]

-- [ [2],      [3],
--   [0,4],    [1,4],
--   [3,2,5],
--   [4,6],
--   [5,9,8],
--   [],       [6],     [6,10],
--   [9]
-- ]

--------------------------------------------------------------------------------

testSkylineD :: [[Int]]
testSkylineD = [
    [2, 1, 3],
    [1, 2, 2],
    [2, 1, 1],
    [1, 1, 4],
    [2, 3, 1],
    [1, 2, 1, 1, 1],
    [2, 1, 1, 1, 1]
  ]

-- 5 #  ####
-- 4 ## #XXX
-- 3 ####X##
-- 2 XXX#XXX
-- 1 #X#X#X#
-- 0 #######
--   ABCDEFG

-- 2,6  1,I  2,I  1,I  2,I  1,4,I  2,4,6
-- 2,6  1,6  2,I  1,I  2,I  1,4,6  2,4,6
-- 2,6  1,6  2,6  1,I  2,6  1,4,6  2,4,6
-- 2,6  1,6  2,6  1,6  2,6  1,4,6  2,4,6
-- 2,6  1,6  2,6  1,6  2,6  1,4,6  2,4,6

-- [ (0,2,1), (0,6,0),
--   (1,1,2), (1,5,0),
--   (2,2,1), (2,4,0),
--   (3,1,1), (3,6,0),
--   (4,2,3), (4,6,0),
--   (5,1,2), (5,4,1), (5,6,0),
--   (6,2,1), (6,4,1), (6,6,0)
-- ]

-- [ [2],     [3],
--   [0,4],   [1,5],
--   [2],     [3,7],
--   [],      [5,9],
--   [11,10], [7,12],
--   [8,13],  [8,14], [9,15],
--   [10],    [11],   [12]
-- ]
