
{-# LANGUAGE DuplicateRecordFields #-}

{-# LANGUAGE OverloadedRecordDot #-}

{-# LANGUAGE UndecidableInstances #-}

module HydraPay.Cardano.Hydra.Api.V1 where

import GHC.Generics
import Data.Aeson
import Data.Text (Text)
import Data.Time (UTCTime)
import Data.Map (Map)

-- import Hydra.API.ClientInput (ClientInput)

-- import Hydra.Chain (PostChainTx, PostTxError)

-- import Hydra.Chain.ChainState (ChainStateType, IsChainState)

-- import Hydra.HeadLogic.State (ClosedState (..), HeadState (..), InitialState (..), OpenState (..), SeenSnapshot (..))

-- import Hydra.HeadLogic.State qualified as HeadState

-- import Hydra.Ledger (ValidationError)

-- import Hydra.Network (Host, ProtocolVersion)

-- import Hydra.Node.Environment (Environment (..))

-- import Hydra.Node.State (NodeState)

-- import Hydra.Prelude hiding (seq)

-- import Hydra.Tx (HeadId, Party, Snapshot, SnapshotNumber, getSnapshot)

-- import Hydra.Tx qualified as Tx

-- import Hydra.Tx.ContestationPeriod (ContestationPeriod)

-- import Hydra.Tx.Crypto (MultiSignature)

-- import Hydra.Tx.IsTx (ArbitraryIsTx, IsTx (..))

-- import Hydra.Tx.OnChainId (OnChainId)

-- import Hydra.Tx.Snapshot (ConfirmedSnapshot (..), Snapshot (..))

-- import Hydra.Tx.Snapshot qualified as HeadState

-- import Test.QuickCheck (recursivelyShrink)

-- import Test.QuickCheck.Arbitrary.ADT (ToADTArbitrary)

type ProtocolVersion = Value
type Host = Value
type HeadId = Value
type Party = Value
type UTxOType a = Value
type SnapshotNumber = Value
type TxIdType a = Value
type ValidationError = Value
type Snapshot a = Value
type MultiSignature a = Value
type ContestationPeriod = Value
type OnChainId = Value
type DecommitInvalidReason a = Value
type NodeState a = Value
type Environment = Value

data Greetings = Greetings
  { me :: Party
  , headStatus :: HeadStatus
  , hydraHeadId :: Maybe HeadId
  , snapshotUtxo :: Maybe (UTxOType ())
  , hydraNodeVersion :: String
  , env :: Environment
  , networkInfo :: NetworkInfo
  }
  deriving (Generic, Show)

instance FromJSON Greetings
instance ToJSON Greetings

data HeadStatus
  = Idle
  | Initializing
  | Open
  | Closed
  | FanoutPossible
  deriving stock (Eq, Show, Generic)

instance FromJSON HeadStatus
instance ToJSON HeadStatus

data NetworkInfo = NetworkInfo
  { networkConnected :: Bool
  , peersInfo :: Map Host Bool
  }
  deriving stock (Eq, Show, Generic)

instance FromJSON NetworkInfo
instance ToJSON NetworkInfo

data ServerOutput tx

  = NetworkConnected

  | NetworkDisconnected

  | NetworkVersionMismatch {ourVersion :: ProtocolVersion, theirVersion :: Maybe ProtocolVersion}

  | NetworkClusterIDMismatch {clusterPeers :: Text, misconfiguredPeers :: Text}

  | PeerConnected {peer :: Host}

  | PeerDisconnected {peer :: Host}

  | HeadIsInitializing {headId :: HeadId, parties :: [Party]}

  | Committed {headId :: HeadId, party :: Party, utxo :: UTxOType tx}

  | HeadIsOpen {headId :: HeadId, utxo :: UTxOType tx}

  | HeadIsClosed

      { headId :: HeadId

      , snapshotNumber :: SnapshotNumber

      , contestationDeadline :: UTCTime

      }

  | HeadIsContested {headId :: HeadId, snapshotNumber :: SnapshotNumber, contestationDeadline :: UTCTime}

  | ReadyToFanout {headId :: HeadId}

  | HeadIsAborted {headId :: HeadId, utxo :: UTxOType tx}

  | HeadIsFinalized {headId :: HeadId, utxo :: UTxOType tx}

  | TxValid {headId :: HeadId, transactionId :: TxIdType tx}

  | TxInvalid {headId :: HeadId, utxo :: UTxOType tx, transaction :: tx, validationError :: ValidationError}

  | SnapshotConfirmed

      { headId :: HeadId

      , snapshot :: Snapshot tx

      , signatures :: MultiSignature (Snapshot tx)

      }

  | IgnoredHeadInitializing

      { headId :: HeadId

      , contestationPeriod :: ContestationPeriod

      , parties :: [Party]

      , participants :: [OnChainId]

      }

  | DecommitRequested {headId :: HeadId, decommitTx :: tx, utxoToDecommit :: UTxOType tx}

  | DecommitInvalid {headId :: HeadId, decommitTx :: tx, decommitInvalidReason :: DecommitInvalidReason tx}

  | DecommitApproved {headId :: HeadId, decommitTxId :: TxIdType tx, utxoToDecommit :: UTxOType tx}

  | DecommitFinalized {headId :: HeadId, distributedUTxO :: UTxOType tx}

  | CommitRecorded

      { headId :: HeadId

      , utxoToCommit :: UTxOType tx

      }

  | DepositActivated {headId :: HeadId, depositTxId :: TxIdType tx, deadline :: UTCTime, chainTime :: UTCTime}

  | DepositExpired {headId :: HeadId, depositTxId :: TxIdType tx, deadline :: UTCTime, chainTime :: UTCTime}

  | CommitApproved {headId :: HeadId, utxoToCommit :: UTxOType tx}

  | CommitFinalized {headId :: HeadId, depositTxId :: TxIdType tx}

  | CommitRecovered {headId :: HeadId, recoveredUTxO :: UTxOType tx, recoveredTxId :: TxIdType tx}

  | SnapshotSideLoaded {headId :: HeadId, snapshotNumber :: SnapshotNumber}

  | EventLogRotated {checkpoint :: NodeState tx}

  deriving stock (Generic)

instance FromJSON (ServerOutput a)
instance ToJSON (ServerOutput a)
