------------------------------------------------------------------------
-- |
-- Module      :  Math.Geometry.HexGridInternal
-- Copyright   :  (c) Amy de Buitléir 2012-2017
-- License     :  BSD-style
-- Maintainer  :  amy@nualeargais.ie
-- Stability   :  experimental
-- Portability :  portable
--
-- A module containing private @HexGrid@ internals. Most developers 
-- should use @HexGrid@ instead. This module is subject to change 
-- without notice.
--
------------------------------------------------------------------------
{-# LANGUAGE TypeFamilies, FlexibleContexts, DeriveGeneric #-}

module Math.Geometry.Grid.HexagonalInternal where

import Prelude hiding (null)
import Data.Function (on)
import Data.List (groupBy, sortBy)
import Data.Ord (comparing)
import GHC.Generics (Generic)
import Math.Geometry.GridInternal

data HexDirection = West | Northwest | Northeast | East | Southeast | 
                      Southwest deriving (Show, Eq, Generic, Ord, Enum, Bounded)

-- | An unbounded grid with hexagonal tiles
--   The grid and its indexing scheme are illustrated in the user guide,
--   available at <https://github.com/mhwombat/grid/wiki>.
data UnboundedHexGrid = UnboundedHexGrid deriving (Show, Eq, Generic)

instance Grid UnboundedHexGrid where
  type Index UnboundedHexGrid = (Int, Int)
  type Direction UnboundedHexGrid = HexDirection
  indices _ = undefined
  neighbours _ (x,y) = 
    [(x-1,y), (x-1,y+1), (x,y+1), (x+1,y), (x+1,y-1), (x,y-1)]
  distance _ (x1, y1) (x2, y2) = 
    maximum [abs (x2-x1), abs (y2-y1), abs(z2-z1)]
    where z1 = -x1 - y1
          z2 = -x2 - y2
  directionTo _ (x1, y1) (x2, y2) = f1 . f2 . f3 . f4 . f5 . f6 $ []
    where f1 ds =  if dx < 0 && dz > 0 then West:ds else ds
          f2 ds =  if dx < 0 && dy > 0 then Northwest:ds else ds
          f3 ds =  if dy > 0 && dz < 0 then Northeast:ds else ds
          f4 ds =  if dx > 0 && dz < 0 then East:ds else ds
          f5 ds =  if dx > 0 && dy < 0 then Southeast:ds else ds
          f6 ds =  if dy < 0 && dz > 0 then Southwest:ds else ds
          dx = x2 - x1
          dy = y2 - y1
          z1 = -x1 - y1
          z2 = -x2 - y2
          dz = z2 - z1
  contains _ _ = True
  null _ = False
  nonNull _ = True

--
-- Hexagonal grids with hexagonal tiles
--

-- | A hexagonal grid with hexagonal tiles
--   The grid and its indexing scheme are illustrated in the user guide,
--   available at <https://github.com/mhwombat/grid/wiki>.
data HexHexGrid = HexHexGrid Int [(Int, Int)] deriving (Eq, Generic)

instance Show HexHexGrid where show (HexHexGrid s _) = "hexHexGrid " ++ show s

instance Grid HexHexGrid where
  type Index HexHexGrid = (Int, Int)
  type Direction HexHexGrid = HexDirection
  indices (HexHexGrid _ xs) = xs
  neighbours = neighboursBasedOn UnboundedHexGrid
  distance = distanceBasedOn UnboundedHexGrid
  directionTo = directionToBasedOn UnboundedHexGrid
  contains g (x,y) = -s < x && x < s && check
    where s = size g
          check = if x < 0
                    then -s-x < y && y < s
                    else -s < y && y < s-x

instance FiniteGrid HexHexGrid where
  type Size HexHexGrid = Int
  size (HexHexGrid s _) = s
  maxPossibleDistance g@(HexHexGrid s _) = distance g (-s+1,0) (s-1,0)

instance BoundedGrid HexHexGrid where
  tileSideCount _ = 6
  boundary g = 
    north ++ northeast ++ southeast ++ south ++ southwest ++ northwest
    where s = size g
          north = [(k,s-1) | k <- [-s+1,-s+2..0]]
          northeast = [(k,s-1-k) | k <- [1,2..s-1]]
          southeast = [(s-1,k) | k <- [-1,-2..(-s)+1]]
          south = [(k,(-s)+1) | k <- [s-2,s-3..0]]
          southwest = [(k,(-s)+1-k) | k <- [-1,-2..(-s)+1]]
          northwest = [(-s+1,k) | k <- [1,2..s-2]]
  centre _ = [(0,0)]

-- | @'hexHexGrid' s@ returns a grid of hexagonal shape, with
--   sides of length @s@, using hexagonal tiles. If @s@ is nonnegative, the 
--   resulting grid will have @3*s*(s-1) + 1@ tiles. Otherwise, the resulting 
--   grid will be null and the list of indices will be null.
hexHexGrid :: Int -> HexHexGrid
hexHexGrid r = HexHexGrid r [(x, y) | x <- [-r+1..r-1], y <- f x]
  where f x = if x < 0 then [1-r-x .. r-1] else [1-r .. r-1-x]

--
-- Parallelogrammatical grids with hexagonal tiles
--

-- | A parallelogramatical grid with hexagonal tiles
--   The grid and its indexing scheme are illustrated in the user guide,
--   available at <https://github.com/mhwombat/grid/wiki>.
data ParaHexGrid = ParaHexGrid (Int, Int) [(Int, Int)]
  deriving (Eq, Generic)

instance Show ParaHexGrid where 
  show (ParaHexGrid (r,c) _) = "paraHexGrid " ++ show r ++ " " ++ show c

instance Grid ParaHexGrid where
  type Index ParaHexGrid = (Int, Int)
  type Direction ParaHexGrid = HexDirection
  indices (ParaHexGrid _ xs) = xs
  neighbours = neighboursBasedOn UnboundedHexGrid
  distance = distanceBasedOn UnboundedHexGrid
  directionTo = directionToBasedOn UnboundedHexGrid
  contains g (x,y) = 0 <= x && x < c && 0 <= y && y < r
    where (r,c) = size g

instance FiniteGrid ParaHexGrid where
  type Size ParaHexGrid = (Int, Int)
  size (ParaHexGrid s _) = s
  maxPossibleDistance g@(ParaHexGrid (r,c) _) = 
    distance g (0,0) (c-1,r-1)

instance BoundedGrid ParaHexGrid where
  tileSideCount _ = 6
  boundary g = cartesianIndices . size $ g
  centre g | length xs == 1  = map fst . head $ xs
           | length xs == 2  = map fst . concat $ xs
           | length xs == 3  = map fst . head . drop 1 $ xs
           | otherwise      = error "logic error"
    where xs = groupBy ((==) `on` snd) . sortBy (comparing snd)
                 . map (\a -> (a,fst a + snd a))
                 . cartesianCentre . size $ g

-- | @'paraHexGrid' r c@ returns a grid in the shape of a 
--   parallelogram with @r@ rows and @c@ columns, using hexagonal tiles. If 
--   @r@ and @c@ are both nonnegative, the resulting grid will have @r*c@ tiles.
--   Otherwise, the resulting grid will be null and the list of indices will 
--   be null.
paraHexGrid :: Int -> Int -> ParaHexGrid
paraHexGrid r c = 
  ParaHexGrid (r,c) [(x, y) | x <- [0..c-1], y <- [0..r-1]]

