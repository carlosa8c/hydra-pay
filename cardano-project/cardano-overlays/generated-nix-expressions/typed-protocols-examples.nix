{ mkDerivation, base, bytestring, cborg, contra-tracer, directory
, fetchzip, io-classes, io-sim, lib, network, QuickCheck, serialise
, si-timers, singletons, tasty, tasty-quickcheck, time
, typed-protocols, typed-protocols-cborg, typed-protocols-stateful
, unix
, src  # Add src as parameter so it can be overridden from the overlay
}:
mkDerivation {
  pname = "typed-protocols-examples";
  version = "0.5.0.0";
  inherit src;
  postUnpack = "sourceRoot+=/typed-protocols-examples; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    base bytestring cborg contra-tracer io-classes network serialise
    si-timers singletons time typed-protocols typed-protocols-cborg
    typed-protocols-stateful
  ];
  testHaskellDepends = [
    base bytestring contra-tracer directory io-classes io-sim network
    QuickCheck si-timers tasty tasty-quickcheck typed-protocols
    typed-protocols-cborg unix
  ];
  description = "Examples and tests for the typed-protocols framework";
  license = lib.licenses.asl20;
}
