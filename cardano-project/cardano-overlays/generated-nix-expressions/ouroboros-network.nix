{ mkDerivation, aeson, array, async, base, base16-bytestring
, bytestring, cardano-binary, cardano-prelude, cardano-slotting
, cardano-strict-containers, cborg, constraints, containers
, contra-tracer, cryptohash-sha256, deepseq, deque, directory
, dlist, dns, fetchzip, hashable, io-classes, io-sim, iproute, lib
, measures, monoidal-synchronisation, mtl, network, network-mux
, nothunks, optparse-applicative, pipes, pretty-simple, process
, psqueues, QuickCheck, quickcheck-instances, quiet, random
, serialise, singletons, splitmix, strict-checked-vars, tasty
, tasty-bench, tasty-expected-failure, tasty-hunit
, tasty-quickcheck, text, time, transformers, typed-protocols
, Win32-network, with-utf8
, src  # Add src as parameter so it can be overridden from the overlay
}:
mkDerivation {
  pname = "ouroboros-network";
  version = "0.23.0.0";
  inherit src;
  postUnpack = "sourceRoot+=/ouroboros-network; echo source root reset to $sourceRoot";
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson array base base16-bytestring bytestring cardano-binary
    cardano-prelude cardano-slotting cardano-strict-containers cborg
    constraints containers contra-tracer deepseq deque directory dlist
    dns hashable io-classes io-sim iproute measures
    monoidal-synchronisation mtl network network-mux nothunks pipes
    pretty-simple psqueues QuickCheck quickcheck-instances quiet random
    serialise singletons splitmix strict-checked-vars tasty
    tasty-expected-failure tasty-hunit tasty-quickcheck text time
    transformers typed-protocols Win32-network
  ];
  executableHaskellDepends = [
    async base bytestring contra-tracer directory hashable io-classes
    network network-mux optparse-applicative random typed-protocols
  ];
  testHaskellDepends = [
    aeson base bytestring cardano-binary cborg containers contra-tracer
    directory io-classes io-sim iproute monoidal-synchronisation
    network network-mux pretty-simple process psqueues QuickCheck
    quickcheck-instances quiet random serialise tasty tasty-quickcheck
    text time typed-protocols with-utf8
  ];
  benchmarkHaskellDepends = [
    base bytestring cryptohash-sha256 deepseq nothunks splitmix
    tasty-bench
  ];
  doHaddock = false;
  description = "A networking layer for the Ouroboros blockchain protocol";
  license = lib.licenses.asl20;
}
