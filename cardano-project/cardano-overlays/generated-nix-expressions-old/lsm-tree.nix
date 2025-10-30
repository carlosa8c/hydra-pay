{ mkDerivation, ansi-terminal, async, barbies, base, binary, bitvec
, blockio, bloomfilter-blocked, bytestring, cborg, clock
, constraints, containers, contra-tracer, crc32c, criterion
, cryptohash-sha256, data-elevator, deepseq, directory
, filepath, fs-api, fs-sim, heaps, indexed-traversable, io-classes
, io-sim, lib, mtl, nonempty-containers, nothunks
, optparse-applicative, pretty-show, primes, primitive, QuickCheck
, quickcheck-classes, quickcheck-dynamic, quickcheck-instances
, quickcheck-lockstep, random, safe-wild-cards, semialign
, serialise, split, splitmix, src, tasty, tasty-bench, tasty-golden
, tasty-hunit, tasty-quickcheck, temporary, text, these, time
, transformers, utf8-string, vector, vector-algorithms, wide-word
}:
mkDerivation {
  pname = "lsm-tree";
  version = "1.0.0.0";
  inherit src;
  postUnpack = "sourceRoot+=/lsm-tree; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    base binary bitvec blockio bloomfilter-blocked bytestring cborg
    containers contra-tracer crc32c data-elevator deepseq filepath
    fs-api fs-sim indexed-traversable io-classes nonempty-containers
    nothunks primes primitive QuickCheck quickcheck-instances random
    serialise text transformers utf8-string vector vector-algorithms
    wide-word
  ];
  testHaskellDepends = [
    ansi-terminal barbies base bitvec blockio bloomfilter-blocked
    bytestring cborg constraints containers contra-tracer crc32c
    cryptohash-sha256 deepseq directory filepath fs-api fs-sim heaps
    io-classes io-sim mtl nothunks primitive QuickCheck
    quickcheck-classes quickcheck-dynamic quickcheck-instances
    quickcheck-lockstep random safe-wild-cards semialign split splitmix
    tasty tasty-bench tasty-golden tasty-hunit tasty-quickcheck
    temporary text these transformers vector vector-algorithms
    wide-word
  ];
  benchmarkHaskellDepends = [
    async base blockio bloomfilter-blocked bytestring clock containers
    contra-tracer criterion deepseq directory fs-api heaps io-classes
    mtl optparse-applicative pretty-show primitive QuickCheck random
    splitmix tasty tasty-bench tasty-hunit tasty-quickcheck temporary
    time transformers vector vector-algorithms wide-word
  ];
  doHaddock = false;
  description = "Log-structured merge-trees";
  license = lib.licenses.asl20;
}
