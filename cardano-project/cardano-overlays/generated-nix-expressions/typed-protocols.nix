{ mkDerivation, base, fetchzip, io-classes, lib, singletons
, src  # Add src as parameter so it can be overridden from the overlay
}:
mkDerivation {
  pname = "typed-protocols";
  version = "0.3.0.0";
  inherit src;
  postUnpack = "sourceRoot+=/typed-protocols; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [ base io-classes singletons ];
  description = "A framework for strongly typed protocols";
  license = lib.licenses.asl20;
}
