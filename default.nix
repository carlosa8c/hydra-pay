{ system ? builtins.currentSystem
, nixpkgs ? import <nixpkgs> {}
, cardanoProject ? import ./cardano-project {
    inherit system nixpkgs;
  }
}:
with cardanoProject;
with obelisk;
let
  foldExtensions = lib.foldr lib.composeExtensions (_: _: {});
  # Resolve nix-thunks by importing thunk.nix when present to get the real source path
  realizeThunk = dir:
    let listing = builtins.readDir dir; in
    if listing ? "thunk.nix" then import (dir + "/thunk.nix") else dir;
  # Build deps attrset of realized thunks so consumers see actual sources
  deps =
    let
      dir = ./dep;
      entries = builtins.readDir dir;
    in builtins.mapAttrs (name: _type: realizeThunk (dir + "/${name}")) entries;
  flake-compat = import deps.flake-compat;
  hydra = (flake-compat {
    inherit system;
    src = deps.hydra;
  }).defaultNix.packages.${system};
  cardano-node = import deps.cardano-node {};
  pkgs = nixpkgs;
  livedoc-devnet-script = pkgs.runCommand "livedoc-devnet-script" { } ''
    cp -r ${./livedoc-devnet} $out
  '';
  p = project ./. ({ pkgs, ... }@args:
    let
      pd = cardanoProjectDef args;
      haskellLib = pkgs.haskell.lib;
    in
    pkgs.lib.recursiveUpdate pd {
      packages =
      {
        hydra-pay = ./hydra-pay;
        hydra-pay-core = ./hydra-pay-core;
        cardano-transaction = pkgs.hackGet ./dep/cardano-transaction-builder;
        bytestring-aeson-orphans = pkgs.hackGet ./dep/bytestring-aeson-orphans;
      };

      overrides = self: super: pd.overrides self super // {
        plutus-tx = haskellLib.dontCheck super.plutus-tx;

        bytestring-aeson-orphans = haskellLib.doJailbreak super.bytestring-aeson-orphans;
        aeson-gadt-th = haskellLib.dontCheck (haskellLib.doJailbreak (haskellLib.disableCabalFlag (
          self.callPackage ./cardano-project/cardano-overlays/generated-nix-expressions/aeson-gadt-th.nix {
            src = deps.aeson-gadt-th;
          }
        ) "build-readme"));
        string-interpolate = haskellLib.doJailbreak (haskellLib.dontCheck super.string-interpolate);

        cardano-transaction = haskellLib.overrideCabal super.cardano-transaction (drv: {
          librarySystemDepends = (drv.librarySystemDepends or []) ++ [
            cardano-node.cardano-cli
          ];
        });

        backend = haskellLib.overrideCabal super.backend (drv: {
          librarySystemDepends = (drv.librarySystemDepends or []) ++ [
            cardano-node.cardano-node
            cardano-node.cardano-cli
            hydra.hydra-node
          ];
        });

        hydra-pay = haskellLib.overrideCabal super.hydra-pay (drv: {
          librarySystemDepends = (drv.librarySystemDepends or []) ++ [
            cardano-node.cardano-node
            cardano-node.cardano-cli
            hydra.hydra-node
          ];
        });
      };
    });
in
# Note: avoid haskell.lib.justStaticExecutables here due to incompatibility with
# the generic builder in the pinned nixpkgs (unexpected arg 'disallowGhcReference').
# Use the plain package output instead; static linking can be revisited later.
p // { hydra-pay = p.ghc.hydra-pay; inherit cardano-node hydra deps;}
