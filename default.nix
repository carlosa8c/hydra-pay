# Simplified default.nix for backend-only build (no Obelisk, no mobile, no GHCJS)
# Focus: hydra-pay, hydra-pay-core, backend packages with modern Cardano/Hydra support
{ system ? builtins.currentSystem
, nixpkgs ? import <nixpkgs> {}
}:
let
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
  
  # Import Cardano project configuration (will be updated to use haskell.nix with GHC 9.6.6)
  cardanoProject = import ./cardano-project {
    inherit system nixpkgs;
  };
  
  # Import hydra-node from thunk using flake-compat
  flake-compat = import deps.flake-compat;
  hydra = (flake-compat {
    inherit system;
    src = deps.hydra;
  }).defaultNix.packages.${system};
  
  # Import cardano-node from thunk
  cardano-node = import deps.cardano-node {};
  
  pkgs = nixpkgs;
  haskellLib = pkgs.haskell.lib;
  
  # Build our Haskell packages using cardanoProject configuration
  # Note: cardanoProject provides the project function which sets up the Haskell build environment
  haskellPackages = cardanoProject.project ./. ({ pkgs, ... }@args:
    let
      pd = cardanoProject.cardanoProjectDef args;
    in
    pkgs.lib.recursiveUpdate pd {
      # NOTE: Don't define 'packages' here! 
      # haskell.nix discovers packages from cabal.project automatically.
      # Defining 'packages' here causes NixOS module system to try importing them as modules.
      
      overrides = self: super: pd.overrides self super // {
        # Don't run tests for plutus-tx (slow, not needed for our use case)
        plutus-tx = haskellLib.dontCheck super.plutus-tx;

        # quickcheck-instances is DEPRECATED - all instances now in QuickCheck 2.17.1.0 (bundled with GHC 9.6.7)
        # Set to null to avoid duplicate instance errors
        quickcheck-instances = null;

        # Package-specific overrides
        bytestring-aeson-orphans = haskellLib.doJailbreak super.bytestring-aeson-orphans;
        
        aeson-gadt-th = haskellLib.dontCheck (haskellLib.doJailbreak (haskellLib.disableCabalFlag (
          self.callPackage ./cardano-project/cardano-overlays/generated-nix-expressions/aeson-gadt-th.nix {
            src = deps.aeson-gadt-th;
          }
        ) "build-readme"));
        
        string-interpolate = haskellLib.doJailbreak (haskellLib.dontCheck super.string-interpolate);

        # Add system dependencies (cardano-node, cardano-cli, hydra-node)
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
# Export the built packages and dependencies
# Note: With haskell.nix, packages are exposed as .components.exes.executable-name
haskellPackages // {
  # Expose main executables from haskell.nix project
  backend = haskellPackages.backend.components.exes.backend or haskellPackages.backend;
  hydra-pay = haskellPackages.hydra-pay.components.exes.hydra-pay or haskellPackages.hydra-pay;
  hydra-pay-core = haskellPackages.hydra-pay-core or null;  # Library package, no exe
  
  # Expose external dependencies for reference
  inherit cardano-node hydra deps;
}
