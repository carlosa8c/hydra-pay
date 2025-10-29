module Backend where

import HydraPay
import HydraPay.PortRange
import HydraPay.Database
import HydraPay.Logging
import HydraPay.Cardano.Hydra
import HydraPay.Utils

import Common.Route

import qualified HydraPay.Database as Db

import Control.Exception
import Control.Lens
import Control.Monad
import Network.WebSockets as WS
import Network.WebSockets.Snap as WS
import Reflex.Dom.GadtApi.WebSocket

import qualified Cardano.Api as Api
import qualified Data.Aeson as Aeson

import Snap.Core
import Snap.Http.Server

-- Main backend application
runBackend :: Int -> String -> IO ()
runBackend port bind = do
  -- Run the Hydra Pay instance (this is where the real logic is)
  runPreviewInstance
