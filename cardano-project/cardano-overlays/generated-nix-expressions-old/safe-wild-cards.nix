{ mkDerivation, base, lib, template-haskell
, th-abstraction, src
}:
mkDerivation {
  pname = "safe-wild-cards";
  version = "1.0.0.2";
  inherit src;
  libraryHaskellDepends = [ base template-haskell th-abstraction ];
  testHaskellDepends = [ base ];
  homepage = "https://github.com/amesgen/safe-wild-cards";
  description = "Use RecordWildCards safely";
  license = lib.licenses.bsd3;
}
