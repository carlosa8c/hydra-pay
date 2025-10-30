{ mkDerivation, aeson, aeson-pretty, attoparsec, barbies, base
, base16-bytestring, base58-bytestring, base64-bytestring, basement
, bech32, bytestring, bytestring-trie, cardano-addresses
, cardano-binary, cardano-crypto, cardano-crypto-class
, cardano-crypto-test, cardano-crypto-tests, cardano-crypto-wrapper
, cardano-data, cardano-ledger-allegra, cardano-ledger-alonzo
, cardano-ledger-api, cardano-ledger-babbage, cardano-ledger-binary
, cardano-ledger-byron, cardano-ledger-conway, cardano-ledger-core
, cardano-ledger-dijkstra, cardano-ledger-mary
, cardano-ledger-shelley, cardano-protocol-tpraos, cardano-slotting
, cardano-strict-containers, cborg, containers, contra-tracer
, crypton, data-default, data-default-class, deepseq, directory
, either, errors, extra, FailT, filepath, formatting
, generic-random, groups, hedgehog, hedgehog-extras
, hedgehog-quickcheck, iproute, lib, memory, microlens
, mono-traversable, mtl, network, network-mux, nothunks
, ordered-containers, ouroboros-consensus
, ouroboros-consensus-cardano, ouroboros-consensus-diffusion
, ouroboros-consensus-protocol, ouroboros-network
, ouroboros-network-api, ouroboros-network-framework
, ouroboros-network-protocols, parsec, plutus-core
, plutus-ledger-api, pretty-simple, prettyprinter
, prettyprinter-ansi-terminal, prettyprinter-configurable
, QuickCheck, quickcheck-instances, random, raw-strings-qq
, safe-exceptions, scientific, serialise, singletons, small-steps
, sop-core, sop-extras, stm, strict-sop-core, tasty, tasty-discover
, tasty-hedgehog, tasty-quickcheck, text, time, transformers
, transformers-except, typed-protocols, unix, validation, vector
, yaml
, src  # Add src as a parameter so it can be overridden from the overlay
}:
mkDerivation {
  pname = "cardano-api";
  version = "10.19.0.0";
  inherit src;  # Use the src passed as parameter
  postUnpack = "sourceRoot+=/cardano-api; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    aeson aeson-pretty attoparsec barbies base base16-bytestring
    base58-bytestring base64-bytestring basement bech32 bytestring
    bytestring-trie cardano-addresses cardano-binary cardano-crypto
    cardano-crypto-class cardano-crypto-test cardano-crypto-wrapper
    cardano-data cardano-ledger-allegra cardano-ledger-alonzo
    cardano-ledger-api cardano-ledger-babbage cardano-ledger-binary
    cardano-ledger-byron cardano-ledger-conway cardano-ledger-core
    cardano-ledger-dijkstra cardano-ledger-mary cardano-ledger-shelley
    cardano-protocol-tpraos cardano-slotting cardano-strict-containers
    cborg containers contra-tracer crypton data-default-class deepseq
    directory either errors extra FailT filepath formatting
    generic-random groups hedgehog hedgehog-extras hedgehog-quickcheck
    iproute memory microlens mono-traversable mtl network network-mux
    nothunks ordered-containers ouroboros-consensus
    ouroboros-consensus-cardano ouroboros-consensus-diffusion
    ouroboros-consensus-protocol ouroboros-network
    ouroboros-network-api ouroboros-network-framework
    ouroboros-network-protocols parsec plutus-core plutus-ledger-api
    pretty-simple prettyprinter prettyprinter-ansi-terminal
    prettyprinter-configurable QuickCheck quickcheck-instances random
    safe-exceptions scientific serialise singletons small-steps
    sop-core sop-extras stm strict-sop-core tasty tasty-hedgehog text
    time transformers transformers-except typed-protocols unix
    validation vector yaml
  ];
  testHaskellDepends = [
    aeson base base16-bytestring base64-bytestring bech32 bytestring
    cardano-binary cardano-crypto cardano-crypto-class
    cardano-crypto-tests cardano-crypto-wrapper cardano-data
    cardano-ledger-alonzo cardano-ledger-api cardano-ledger-binary
    cardano-ledger-conway cardano-ledger-core cardano-ledger-mary
    cardano-ledger-shelley cardano-protocol-tpraos cardano-slotting
    cborg containers data-default directory errors FailT filepath
    hedgehog hedgehog-extras hedgehog-quickcheck microlens mtl
    ouroboros-consensus ouroboros-consensus-protocol plutus-core
    plutus-ledger-api QuickCheck raw-strings-qq tasty tasty-discover
    tasty-hedgehog tasty-quickcheck text time
  ];
  testToolDepends = [ tasty-discover ];
  doHaddock = false;
  description = "The cardano API";
  license = lib.licenses.asl20;
}
