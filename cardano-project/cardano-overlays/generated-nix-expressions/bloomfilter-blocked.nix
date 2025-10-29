{ mkDerivation, base, bytestring, containers, criterion, deepseq
, directory, lib, parallel, primitive
, quickcheck-instances, random, regression-simple, src, tasty
, tasty-hunit, tasty-quickcheck
}:
mkDerivation {
  pname = "bloomfilter-blocked";
  version = "0.1.0.0";
  inherit src;
  postUnpack = "sourceRoot+=/bloomfilter-blocked; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [ base bytestring deepseq primitive ];
  testHaskellDepends = [
    base bytestring containers directory parallel primitive
    quickcheck-instances random regression-simple tasty tasty-hunit
    tasty-quickcheck
  ];
  benchmarkHaskellDepends = [ base criterion random ];
  doHaddock = false;
  description = "Classic and block-style bloom filters";
  license = lib.licenses.asl20;
}
