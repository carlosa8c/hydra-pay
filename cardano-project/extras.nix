args@{ rpSetup, obelisk, ... }:
{
  haskellOverlaysPre = let deps = rpSetup.nixpkgs.thunkSet ./cardano-overlays/cardano-packages/dep; in [
    (self: super:
      let
        pkgs = self.callPackage ({ pkgs }: pkgs) {};
        haskellLib = pkgs.haskell.lib;
      in
        {
          time-compat = haskellLib.dontCheck super.time-compat;
          text-short = super.text-short;
          quickcheck-instances = haskellLib.doJailbreak super.quickcheck-instances;

          # https://github.com/input-output-hk/plutus/pull/4413
          # Stubs out unused functionality that breaks 32-bit build
          plutus-core = haskellLib.overrideCabal super.plutus-core (drv: {
            doCheck = false;
            doHaddock = false;
            doBenchmark = false;
            preConfigure = ''
              substituteInPlace plutus-core/src/GHC/Natural/Extras.hs \
                --replace "naturalToWord64Maybe n = intCastEq <$> naturalToWordMaybe n" "naturalToWord64Maybe _ = Nothing"

              substituteInPlace plutus-core/src/PlutusCore/Default/Universe.hs \
                --replace "intCastEq @Int @Int64" "const @Int64 @Int 0" \
                --replace "intCastEq @Int64 @Int" "const @Int @Int64 0"
            '';
          });
          # Avoid brittle dependency pins to a concrete installedId of
          # plutus-core:plutus-core-testlib. Instead, disable tests/benches so
          # Cabal won't try to resolve that sub-library at configure time.
          plutus-tx = haskellLib.overrideCabal super.plutus-tx (drv: {
            doCheck = false;
            doBenchmark = false;
            configureFlags = (drv.configureFlags or []) ++ [
              "--disable-tests"
              "--disable-benchmarks"
            ];
            # Remove references to the test/benchmark suites to avoid cabal2nix
            # generating installed-id pins that don't exist in this build.
            postPatch = (drv.postPatch or "") + ''
              sed -i.bak '/^test-suite /,/^$/d' plutus-tx.cabal
              sed -i.bak '/^benchmark /,/^$/d' plutus-tx.cabal
              rm -f plutus-tx.cabal.bak
            '';
          });
        })
  ];
  haskellOverlaysPost = let deps = rpSetup.nixpkgs.thunkSet ./cardano-overlays/cardano-packages/dep; in (args.haskellOverlays or []) ++ (args.haskellOverlaysPost or []) ++ [
    (self: super:
      let
        pkgs = self.callPackage ({ pkgs }: pkgs) {};
        haskellLib = pkgs.haskell.lib;
      in
      {
        time-compat = haskellLib.dontCheck super.time-compat;
      })
  ];
}
