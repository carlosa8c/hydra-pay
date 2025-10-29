{ mkDerivation, array, async, base, bytestring, deepseq, fetchzip
, lib, mtl, nothunks, primitive, QuickCheck, stm, tasty
, tasty-quickcheck, time
, src  # Add src as parameter so it can be overridden from the overlay
}:
mkDerivation {
  pname = "io-classes";
  version = "1.8.0.1";
  inherit src;
  postUnpack = "sourceRoot+=/io-classes; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    array async base bytestring deepseq mtl nothunks primitive
    QuickCheck stm time
  ];
  testHaskellDepends = [ base QuickCheck tasty tasty-quickcheck ];
  doHaddock = false;
  description = "Type classes for concurrency with STM, ST and timing";
  license = lib.licenses.asl20;
}
