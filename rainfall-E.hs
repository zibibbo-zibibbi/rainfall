import qualified Data.Vector.Unboxed as V
import System.Random
import System.CPUTime


rainfall :: V.Vector Int -> Int
rainfall xs = V.sum depths where
  depths = V.zipWith3 (\l r x -> (min l r) - x) maxl maxr xs
  maxl = V.scanl1' max xs
  maxr = V.scanr1' max xs


randVector :: RandomGen g => (Int, Int) -> g -> Int -> V.Vector Int
randVector bs g n = V.unfoldr step (0, g) where
  step (i, g1) = if i < n then let (h, g2) = randomR bs g1 in Just (h, (i+1, g2)) else Nothing


main = do
  g <- getStdGen
  let hs = randVector (0, 200) g 10000000
  putStrLn $ show $ V.sum hs
  startTime <- getCPUTime
  let n = rainfall hs
  putStrLn (show n)
  finishTime <- getCPUTime
  putStrLn (show (fromIntegral (finishTime - startTime) / 1000000000000))
