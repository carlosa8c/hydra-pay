{ mkDerivation, base, bytestring, cborg, fetchzip, io-classes, lib
, singletons, typed-protocols
, src  # Add src as parameter so it can be overridden from the overlay
}:
mkDerivation {
  pname = "typed-protocols-cborg";
  version = "0.3.0.0";
  inherit src;
  postUnpack = "sourceRoot+=/typed-protocols-cborg; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    base bytestring cborg io-classes singletons typed-protocols
  ];
  description = "CBOR codecs for typed-protocols";
  license = lib.licenses.asl20;
}
