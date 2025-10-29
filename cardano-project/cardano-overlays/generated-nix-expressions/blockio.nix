{ mkDerivation, async, base, bytestring, deepseq, fs-api
, fs-sim, io-classes, lib, primitive, QuickCheck, src, tasty
, tasty-hunit, tasty-quickcheck, temporary, unix, vector
}:
mkDerivation {
  pname = "blockio";
  version = "0.1.0.1";
  inherit src;
  postUnpack = "sourceRoot+=/blockio; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    base bytestring deepseq fs-api fs-sim io-classes primitive unix
    vector
  ];
  testHaskellDepends = [
    async base bytestring fs-api fs-sim io-classes primitive QuickCheck
    tasty tasty-hunit tasty-quickcheck temporary vector
  ];
  doHaddock = false;
  description = "Perform batches of disk I/O operations";
  license = lib.licenses.asl20;
}
