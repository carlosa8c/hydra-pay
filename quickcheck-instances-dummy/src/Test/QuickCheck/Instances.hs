-- | Dummy module - QuickCheck 2.17.1.0 has all instances built-in
-- This module exists only for compatibility with packages that import it
-- We re-export all the Arbitrary instances from QuickCheck
module Test.QuickCheck.Instances 
  ( module Test.QuickCheck.Arbitrary
  ) where

import Test.QuickCheck.Arbitrary

-- QuickCheck 2.17.1.0 (GHC 9.6.7) includes all Arbitrary instances that
-- quickcheck-instances used to provide, so we just re-export them
