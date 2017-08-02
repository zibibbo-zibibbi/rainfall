import System.Random
import System.CPUTime


rainfall :: [Int] -> Int
rainfall xs = sum (zipWith (-) mins xs) where
  mins = zipWith min maxl maxr
  maxl = scanl1 max xs
  maxr = scanr1 max xs


main = do
  g <- getStdGen
  let hs = take 10000000 (randomRs (0, 200) g :: [Int])
  startTime <- getCPUTime
  let n = rainfall hs
  putStrLn (show n)
  finishTime <- getCPUTime
  putStrLn (show (fromIntegral (finishTime - startTime) / 1000000000000))
