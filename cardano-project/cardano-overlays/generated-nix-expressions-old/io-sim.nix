{ mkDerivation, array, base, containers, criterion, deepseq
, exceptions, fetchzip, hashable, io-classes, lib, nothunks
, parallel, primitive, psqueues, QuickCheck, quiet, tasty
, tasty-hunit, tasty-quickcheck, time
, src  # Add src as parameter so it can be overridden from the overlay
}:
mkDerivation {
  pname = "io-sim";
  version = "1.8.0.1";
  inherit src;
  postUnpack = "sourceRoot+=/io-sim; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    base containers deepseq exceptions hashable io-classes nothunks
    parallel primitive psqueues QuickCheck quiet time
  ];
  testHaskellDepends = [
    array base containers io-classes QuickCheck tasty tasty-hunit
    tasty-quickcheck time
  ];
  benchmarkHaskellDepends = [ base criterion io-classes ];
  description = "A pure simulator for monadic concurrency with STM";
  license = lib.licenses.asl20;
}
