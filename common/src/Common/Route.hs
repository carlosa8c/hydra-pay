{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Common.Route where

import Data.Text (Text)

-- Simple route types without Obelisk encoder machinery
-- Backend will handle routing with Snap's routing system

data BackendRoute
  = BackendRoute_Missing
  | BackendRoute_Api
  | BackendRoute_HydraPay HydraPayRoute
  deriving (Show, Eq)

data HydraPayRoute
  = HydraPayRoute_Api
  deriving (Show, Eq)

data FrontendRoute
  = FrontendRoute_Monitor
  deriving (Show, Eq)

-- Simple path rendering for URLs
renderHydraPayRoute :: HydraPayRoute -> Text
renderHydraPayRoute = \case
  HydraPayRoute_Api -> "/hydra/api"

renderBackendRoute :: BackendRoute -> Text
renderBackendRoute = \case
  BackendRoute_Missing -> "/missing"
  BackendRoute_Api -> "/api"
  BackendRoute_HydraPay r -> renderHydraPayRoute r

renderFrontendRoute :: FrontendRoute -> Text
renderFrontendRoute = \case
  FrontendRoute_Monitor -> "/"
