{ mkDerivation, base, base16-bytestring, bytestring
, cborg, containers, data-fix, formatting
, hedgehog, hspec, lib, pretty-show, primitive, QuickCheck
, quickcheck-instances, recursion-schemes, safe-exceptions, tagged
, text, time, tree-diff, vector
}:
mkDerivation {
  pname = "cardano-binary";
  version = "1.7.1.0";
  src = ./.;
  libraryHaskellDepends = [
    base base16-bytestring bytestring cborg containers data-fix
    formatting primitive recursion-schemes safe-exceptions tagged text
    time tree-diff vector
  ];
  testHaskellDepends = [
    base bytestring cborg containers formatting
    hedgehog hspec pretty-show QuickCheck quickcheck-instances tagged
    text time vector
  ];
  doHaddock = false;
  description = "Binary serialization for Cardano";
  license = lib.licenses.asl20;
}
