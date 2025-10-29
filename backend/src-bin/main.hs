import Backend
import ParseConfig
import qualified Data.ByteString.UTF8 as BSU

main :: IO ()
main = do
  cfg <- getHydraCLIConfig
  runBackend (_port cfg) (_bind cfg)
